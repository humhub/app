class InitFromPush {
  static String? _redirectUrlFromInit;

  static setPayload(String payload) {
    _redirectUrlFromInit = payload;
  }

  static String? usePayload() {
    String? payload = _redirectUrlFromInit;
    _redirectUrlFromInit = null;
    return payload;
  }
}
