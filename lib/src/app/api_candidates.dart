/// Hospital / local-dev fallback API origins when [API_BASE_URL] is unset.
///
/// The fastest successful `/server-time` probe wins at startup.
const kApiCandidateBaseUrls = <String>[
  'http://localhost:3000',
  'http://192.168.2.121:3000',
  'http://192.168.2.120:3000',
  'http://api.imsh.ng',
];
