const GITHUB_USER = '0Sycamores';
const REPO_NAME = 'SycamoreArchSetup';

export default {
  async fetch(request, env) {
    // 注意这里添加了 env 参数
    const url = new URL(request.url);
    const userAgent = request.headers.get('User-Agent') || '';
    const repoUrl = `https://github.com/${GITHUB_USER}/${REPO_NAME}`;

    // 逻辑判断：如果是命令行工具访问
    if (userAgent.includes('curl') || userAgent.includes('wget')) {
      // 构造指向静态资源 /install.sh 的请求
      const assetUrl = new URL(url);
      assetUrl.pathname = '/install.sh';

      // 使用 Assets Binding 获取文件内容
      // 这比从 GitHub 拉取更快，因为走的是 Cloudflare 内部网络
      return env.ASSETS.fetch(new Request(assetUrl, request));
    }

    // 其他情况跳转到 GitHub
    return Response.redirect(repoUrl, 302);
  },
};
