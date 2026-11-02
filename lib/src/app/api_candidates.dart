/// Local-dev API origin when [API_BASE_URL] is unset.
///
/// Facility hosts belong in `.env`. The fastest successful `/server-time`
/// probe wins at startup.
const kApiCandidateBaseUrls = <String>[
  'http://localhost:3000',
];
