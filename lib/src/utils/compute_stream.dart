import 'dart:isolate';
import 'dart:async';

typedef ComputeStreamCallback<S, Q, R> =
  FutureOr<R> Function(Stream<S> stream, Q message);

Future<R> computeStream<S, Q, R>(
    ComputeStreamCallback<S, Q, R> callback, Stream<S> stream, Q message
) async {
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort streamPort = ReceivePort();
  final ReceivePort exitPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  StreamSubscription<S> subscription;

  final isolate = await Isolate.spawn<_IsolateConfiguration<S, Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<S, Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
      streamPort.sendPort,
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
  streamPort.listen((dynamic streamData) {
    final sendPort = streamData as SendPort;
    subscription = stream.listen(
        (event) {
          sendPort.send(_StreamEvent(event));
        },
        onDone: () {
          sendPort.send(_StreamDone());
        },
        onError: (Object error, StackTrace stackTrace) {
          sendPort.send(_StreamError(error, stackTrace));
        }
    );
  });
  resultPort.listen((dynamic resultData) {
    assert(resultData == null || resultData is R);
    if (!result.isCompleted)
      result.complete(resultData as R);
  });

  await result.future;
  resultPort.close();
  streamPort.close();
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
      this.streamPort,
      );
  final ComputeStreamCallback<S, Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final SendPort streamPort;

  FutureOr<R> apply(Stream<S> stream) => callback(stream, message);
  
  Stream<S> transform(ReceivePort port) => port.transform<S>(
      StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            if (data is _StreamEvent) {
              sink.add(data.value);
            } else if (data is _StreamError) {
              sink.addError(data.error, data.stackTrace);
            } else if (data is _StreamDone) {
              sink.close();
            }
          }
      )
  );
}

class _StreamEvent {
  final Object value;

  const _StreamEvent(this.value);
}

class _StreamError {
  final Object error;
  final StackTrace stackTrace;

  const _StreamError(this.error, this.stackTrace);
}

class _StreamDone {}

Future<void> _spawn<S, Q, R>(
    _IsolateConfiguration<S, Q, FutureOr<R>> configuration
) async {
  ReceivePort inputPort = ReceivePort();
  try {
    configuration.streamPort.send(inputPort.sendPort);
    final stream = configuration.transform(inputPort);
    final applicationResult = await configuration.apply(stream);
    final result = await applicationResult;
    configuration.resultPort.send(result);
  } finally {
    inputPort.close();
  }
}
