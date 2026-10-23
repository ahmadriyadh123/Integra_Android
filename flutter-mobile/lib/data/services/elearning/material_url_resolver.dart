Uri resolveElearningMaterialUri(String contentUrl, String apiBaseUrl) {
  final contentUri = Uri.parse(contentUrl);
  if (contentUri.hasScheme) return contentUri;

  final apiBase = Uri.parse(apiBaseUrl);
  if (contentUri.hasAuthority) return apiBase.resolveUri(contentUri);

  final contentPath = contentUri.path.startsWith('/')
      ? contentUri.path
      : '/${contentUri.path}';
  final basePath = apiBase.path.replaceFirst(RegExp(r'/api/v1/?$'), '');
  final isApiPath =
      contentPath == '/api/v1' || contentPath.startsWith('/api/v1/');
  final resolvedPath = isApiPath && basePath.isNotEmpty
      ? '$basePath$contentPath'
      : contentPath;

  return Uri(
    scheme: apiBase.scheme,
    userInfo: apiBase.userInfo,
    host: apiBase.host,
    port: apiBase.hasPort ? apiBase.port : null,
    path: resolvedPath,
    query: contentUri.hasQuery ? contentUri.query : null,
    fragment: contentUri.hasFragment ? contentUri.fragment : null,
  );
}
