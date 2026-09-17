const { execSync } = require('child_process');
try {
  const val = execSync(`npx wrangler kv key list --binding PUSH_SUBSCRIPTIONS --remote`, { encoding: 'utf8' });
  console.log(val);
} catch (e) {
  console.error(e.message);
}
