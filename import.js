const fs = require('fs');
const readline = require('readline');
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json'))
});

const db = admin.firestore();

async function importData(langCode, filePath, merge) {
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  await db.collection('resume').doc(langCode).set(data, { merge });
  console.log(`✅ Imported ${langCode} (${merge ? 'merged' : 'replaced'}) from ${filePath}`);
}

async function ask(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  return new Promise(resolve => rl.question(question, ans => {
    rl.close();
    resolve(ans.toLowerCase().trim());
  }));
}

(async () => {
  const choice = await ask("Do you want to MERGE (safe overwrite) or REPLACE (full overwrite)? (m/r): ");
  const merge = choice === 'm';

  await importData('en', './assets/profile_en.json', merge);

  try {
    await importData('fr', './assets/profile_fr.json', merge);
  } catch (err) {
    console.warn("⚠️ Skipping French import (file not found).");
  }

  process.exit();
})();