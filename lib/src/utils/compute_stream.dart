import 'dart:isolate';
import 'dart:async';

import 'compute_shared.dart';

typedef ComputeStreamCallback<S, Q, R> =
  FutureOr<R> Function(Stream<S> stream, Q message);

Future<R> computeStream<S, Q, R>(
    ComputeStreamCallback<S, Q, R> callback, Stream<S> stream, Q message
) async {
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort exitPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  late StreamSubscription<S> subscription;

  final isolate = await Isolate.spawn<_IsolateConfiguration<S, Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<S, Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
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
      result.completeError(Exception('Isolate exited without result or error.'));
    }
  });
  resultPort.listen((dynamic resultData) {
    assert(resultData != null);
    if (result.isCompleted) {
      return;
    } else if (resultData is SendPort) {
      subscription = stream.listen(
          (event) {
            resultData.send(StreamEvent(event));
          },
          onDone: () {
            resultData.send(StreamDone());
          },
          onError: (Object error, StackTrace stackTrace) {
            resultData.send(StreamError(error, stackTrace));
          }
      );
    } else if (resultData is StreamEvent) {
      result.complete(resultData.value as R?);
    } else if (resultData is StreamError) {
      result.completeError(resultData.error, resultData.stackTrace);
    }
  });

  await result.future;
  resultPort.close();
  errorPort.close();
  isolate.kill();
  subscription.cancel();
  return result.future;
}

class _IsolateConfiguration<S, Q, R> {
  const _IsolateConfiguration(
      this.callback,
      this.message,
      this.resultPort,
      );
  final ComputeStreamCallback<S, Q, R> callback;
  final Q message;
  final SendPort resultPort;

  FutureOr<R> apply(Stream<S> stream) => callback(stream, message);
  
  Stream<S> transform(ReceivePort port) => port.transform<S>(
      StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (data is StreamEvent) {
              sink.add(data.value as S);
            } else if (data is StreamError) {
              sink.addError(data.error, data.stackTrace);
            } else if (data is StreamDone) {
              sink.close();
            }
          }
      )
  );
}

Future<void> _spawn<S, Q, R>(
    _IsolateConfiguration<S?, Q, FutureOr<R>> configuration
) async {
  ReceivePort inputPort = ReceivePort();
  try {
    configuration.resultPort.send(inputPort.sendPort);
    final stream = configuration.transform(inputPort);
    final FutureOr<R> applicationResult = await configuration.apply(stream);
    final result = await applicationResult;
    configuration.resultPort.send(StreamEvent(result));
  } catch (e, stackTrace) {
    // pass error without loosing its type
    configuration.resultPort.send(StreamError(e, stackTrace));
  } finally {
    inputPort.close();
  }
}
