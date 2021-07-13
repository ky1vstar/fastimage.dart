// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:fastimage/src/utils/compute_shared.dart';
import 'package:meta/meta.dart';

/// Signature for the callback passed to [compute].
///
/// {@macro flutter.foundation.compute.types}
///
/// Instances of [ComputeCallback] must be top-level functions or static methods
/// of classes, not closures or instance methods of objects.
///
/// {@macro flutter.foundation.compute.limitations}
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

const bool kReleaseMode = bool.fromEnvironment(
    'dart.vm.product', defaultValue: false
);

/// The dart:io implementation of [isolate.compute].
Future<R> compute<Q, R>(
    ComputeCallback<Q, R> callback, Q message, { String? debugLabel }
) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();
  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort exitPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  Timeline.finishSync();
  final isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
      debugLabel,
      flow.id,
    ),
    errorsAreFatal: true,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
  );
  final Completer<R> result = Completer<R>();
  errorPort.listen((dynamic errorData) {
    assert(errorData is List<dynamic>);
    assert(errorData.length == 2);
    final Exception exception = Exception(errorData[0]);
    final StackTrace stack = StackTrace.fromString(errorData[1] as String);
    if (result.isCompleted) {
      Zone.current.handleUncaughtError(exception, stack);
    } else {
      result.completeError(exception, stack);
    }
  });
  exitPort.listen((dynamic exitData) {
    if (!result.isCompleted) {
      result.completeError(
          Exception('Isolate exited without result or error.')
      );
    }
  });
  resultPort.listen((dynamic resultData) {
    if (result.isCompleted) {
      return;
    } else if (resultData is StreamEvent) {
      result.complete(resultData.value as R?);
    } else if (resultData is StreamError) {
      result.completeError(resultData.error, resultData.stackTrace);
    }
  });
  await result.future;
  Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
  resultPort.close();
  errorPort.close();
  isolate.kill();
  Timeline.finishSync();
  return result.future;
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
      this.callback,
      this.message,
      this.resultPort,
      this.debugLabel,
      this.flowId,
      );
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(
    _IsolateConfiguration<Q, FutureOr<R>> configuration
) async {
  try {
    final R result = await Timeline.timeSync(
      configuration.debugLabel,
          () async {
        final FutureOr<R> applicationResult = await (configuration.apply() as FutureOr<R>);
        return await applicationResult;
      },
      flow: Flow.step(configuration.flowId),
    );
    Timeline.timeSync(
      '${configuration.debugLabel}: returning result',
          () { configuration.resultPort.send(StreamEvent(result)); },
      flow: Flow.step(configuration.flowId),
    );
  } catch (e, stackTrace) {
    // pass error without loosing its type
    Timeline.timeSync(
      '${configuration.debugLabel}: throwing exception',
          () { configuration.resultPort.send(StreamError(e, stackTrace)); },
      flow: Flow.step(configuration.flowId),
    );
  }
}
