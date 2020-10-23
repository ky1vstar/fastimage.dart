class StreamEvent {
  final Object value;

  const StreamEvent(this.value);
}

class StreamError {
  final Object error;
  final StackTrace stackTrace;

  const StreamError(this.error, this.stackTrace);
}

class StreamDone {}