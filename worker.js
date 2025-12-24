// 1. 直接导入 install.sh 的内容 (利用 wrangler.toml 中的 rules 配置)
import installScript from './install.sh';

const GITHUB_USER = '0Sycamores';
const REPO_NAME = 'SycamoreArchSetup';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const userAgent = request.headers.get('User-Agent') || '';

    // 定义浏览器跳转的目标 (GitHub 仓库主页)
    const repoUrl = `https://github.com/${GITHUB_USER}/${REPO_NAME}`;

    // 2. 逻辑判断：如果是命令行工具访问，直接返回脚本内容
    if (userAgent.includes('curl') || userAgent.includes('wget')) {
      return new Response(installScript, {
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          // 可选：添加缓存控制，避免频繁请求
          'Cache-Control': 'no-cache',
        },
      });
    }

    // 3. 其他情况（如浏览器访问）跳转到仓库主页
    return Response.redirect(repoUrl, 302);
  },
};
