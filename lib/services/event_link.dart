Uri eventPageUri(Uri base, String eventId) => Uri(
  scheme: base.scheme,
  userInfo: base.userInfo,
  host: base.hasAuthority ? base.host : null,
  port: base.hasPort ? base.port : null,
  path: base.path,
  fragment: '/events/${Uri.encodeComponent(eventId)}',
);
