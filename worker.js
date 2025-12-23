// 修改这里的配置
const GITHUB_USER = '0Sycamores';
const REPO_NAME = 'SycamoreArchSetup';
const DEFAULT_BRANCH = 'main';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const userAgent = request.headers.get('User-Agent') || '';

    // 1. 定义跳转目标
    const rawScriptUrl = `https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${DEFAULT_BRANCH}/install.sh`;
    const repoUrl = `https://github.com/${GITHUB_USER}/${REPO_NAME}`;

    // 2. 逻辑判断：如果是命令行工具访问，返回脚本
    if (userAgent.includes('curl') || userAgent.includes('wget')) {
      return Response.redirect(rawScriptUrl, 302);
    }

    // 4. 其他情况（如浏览器访问）跳转到仓库主页
    return Response.redirect(repoUrl, 302);
  },
};
