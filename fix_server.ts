import fs from 'fs';
let content = fs.readFileSync('server.ts', 'utf8');

content = content.replace(
    /}catch \\(contactErr\\) {/,
    '} } catch (contactErr) {'
);

fs.writeFileSync('server.ts', content);
