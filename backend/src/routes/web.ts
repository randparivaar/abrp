import { Hono } from 'hono';
import { db } from '../db/index.js';
import { businessProfiles, businessLocations, businessMembers, familyMembers, families } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';

const webRouter = new Hono();

// Android Digital Asset Links for App Links verification
webRouter.get('/.well-known/assetlinks.json', (c) => {
  return c.json([
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.abrp.mobile_app',
        sha256_cert_fingerprints: [
          '0A:85:F3:FA:E1:AE:A5:91:6D:33:4E:95:05:D9:B4:6E:A8:AD:B5:CD:8B:75:E6:D6:DB:39:49:28:87:07:F5:32',
        ],
      },
    },
  ]);
});

// Web Landing Page for Shared Business Profile
webRouter.get('/business/:id', async (c) => {
  const businessId = parseInt(c.req.param('id'), 10);
  if (isNaN(businessId)) {
    return c.html(renderNotFoundPage('Invalid business identifier.'), 404);
  }

  try {
    const biz = await db.query.businessProfiles.findFirst({
      where: eq(businessProfiles.id, businessId),
    });

    if (!biz) {
      return c.html(renderNotFoundPage('Business profile not found in ABRP Samaj Directory.'), 404);
    }

    const loc = await db.query.businessLocations.findFirst({
      where: and(eq(businessLocations.businessId, businessId), eq(businessLocations.isPrimary, true)),
    });

    const members = await db.query.businessMembers.findMany({
      where: eq(businessMembers.businessId, businessId),
      with: { member: true },
    });

    const ownerNames = members.map((m: any) => m.member?.fullName).filter(Boolean).join(', ');

    return c.html(renderBusinessPage(biz, loc, ownerNames));
  } catch (err: any) {
    console.error('Error rendering business web page:', err);
    return c.html(renderNotFoundPage('Server error loading business profile.'), 500);
  }
});

// Web Landing Page for Shared Member Profile
webRouter.get('/member/:familyId/:memberId', async (c) => {
  const familyId = parseInt(c.req.param('familyId'), 10);
  const memberId = parseInt(c.req.param('memberId'), 10);

  if (isNaN(memberId)) {
    return c.html(renderNotFoundPage('Invalid member identifier.'), 404);
  }

  try {
    const member = await db.query.familyMembers.findFirst({
      where: eq(familyMembers.id, memberId),
    });

    if (!member) {
      return c.html(renderNotFoundPage('Member profile not found in ABRP Samaj Directory.'), 404);
    }

    let villageName = '';
    if (familyId) {
      const family = await db.query.families.findFirst({
        where: eq(families.id, familyId),
        with: { village: true },
      });
      villageName = (family as any)?.village?.name || family?.city || '';
    }

    return c.html(renderMemberPage(member, familyId, villageName));
  } catch (err: any) {
    console.error('Error rendering member web page:', err);
    return c.html(renderNotFoundPage('Server error loading member profile.'), 500);
  }
});

function escapeHtml(str: string | null | undefined): string {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function renderBusinessPage(biz: any, loc: any, ownerNames: string): string {
  const name = escapeHtml(biz.businessName);
  const category = escapeHtml(biz.industryCategory);
  const desc = escapeHtml(biz.description || `${biz.businessName} - ABRP Community Business Profile`);
  const logo = biz.logoUrl ? escapeHtml(biz.logoUrl) : '';
  const city = loc?.city ? escapeHtml(loc.city) : '';
  const address = loc?.address ? escapeHtml(loc.address) : '';
  const mobile = biz.contactMobile ? escapeHtml(biz.contactMobile) : '';
  const website = biz.websiteUrl ? escapeHtml(biz.websiteUrl) : '';
  const mapsUrl = loc?.googleMapsLink ? escapeHtml(loc.googleMapsLink) : '';
  const owners = escapeHtml(ownerNames);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${name} | ABRP Business Directory</title>

  <!-- OpenGraph Metadata for WhatsApp / Facebook / LinkedIn Cards -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="${name} (${category})">
  <meta property="og:description" content="${desc}">
  ${logo ? `<meta property="og:image" content="${logo}">` : ''}
  <meta property="og:url" content="https://abrp.vercel.app/business/${biz.id}">
  <meta property="og:site_name" content="Akhil Bhartiya Rander Parivar">

  <!-- Twitter Meta -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${name}">
  <meta name="twitter:description" content="${desc}">
  ${logo ? `<meta name="twitter:image" content="${logo}">` : ''}

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #FDFBF7;
      color: #1F2937;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .card {
      background: #FFFFFF;
      border: 1px solid #E5E7EB;
      border-radius: 20px;
      max-width: 480px;
      width: 100%;
      box-shadow: 0 10px 30px rgba(0,0,0,0.06);
      overflow: hidden;
      text-align: center;
      padding-bottom: 24px;
    }
    .header-bar {
      background: linear-gradient(135deg, #553D00, #8A6400);
      color: #FFFFFF;
      padding: 24px 20px;
      text-align: center;
    }
    .header-bar h2 {
      font-family: 'Outfit', sans-serif;
      font-size: 16px;
      font-weight: 600;
      letter-spacing: 0.5px;
      opacity: 0.9;
    }
    .avatar-wrapper {
      margin-top: -36px;
      margin-bottom: 12px;
      display: flex;
      justify-content: center;
    }
    .avatar {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: #FFFFFF;
      border: 3px solid #8A6400;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 32px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      overflow: hidden;
    }
    .avatar img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .content {
      padding: 0 24px;
    }
    h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 24px;
      color: #111827;
      margin-bottom: 6px;
    }
    .badge {
      display: inline-block;
      background: #FEF3C7;
      color: #92400E;
      font-size: 12px;
      font-weight: 700;
      padding: 4px 12px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 14px;
    }
    .desc {
      font-size: 14px;
      color: #4B5563;
      line-height: 1.5;
      margin-bottom: 20px;
    }
    .info-list {
      background: #F9FAFB;
      border-radius: 12px;
      padding: 14px 16px;
      text-align: left;
      font-size: 13px;
      color: #374151;
      margin-bottom: 24px;
    }
    .info-item {
      display: flex;
      align-items: flex-start;
      margin-bottom: 8px;
    }
    .info-item:last-child { margin-bottom: 0; }
    .info-item strong {
      min-width: 70px;
      color: #6B7280;
    }
    .btn-open {
      display: block;
      background: linear-gradient(135deg, #553D00, #8A6400);
      color: #FFFFFF !important;
      text-decoration: none;
      font-family: 'Outfit', sans-serif;
      font-size: 16px;
      font-weight: 700;
      padding: 14px;
      border-radius: 12px;
      box-shadow: 0 4px 14px rgba(138, 100, 0, 0.35);
      transition: transform 0.15s ease;
      margin-bottom: 12px;
    }
    .btn-open:active {
      transform: scale(0.98);
    }
    .btn-secondary {
      display: inline-block;
      color: #553D00;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      padding: 8px 16px;
      border-radius: 8px;
      border: 1px solid #D1D5DB;
      margin: 0 4px 12px 4px;
    }
    .footer {
      font-size: 12px;
      color: #9CA3AF;
      margin-top: 16px;
    }
  </style>

  <!-- Auto-launch App via Deep Link or Android Intent -->
  <script>
    (function() {
      var businessId = "${biz.id}";
      var appUrl = "abrp://business/" + businessId;
      var isAndroid = /Android/i.test(navigator.userAgent);
      if (isAndroid) {
        window.location.href = "intent://business/" + businessId + "#Intent;scheme=abrp;package=com.abrp.mobile_app;end";
      } else if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        window.location.href = appUrl;
      }
    })();
  </script>
</head>
<body>
  <div class="card">
    <div class="header-bar">
      <h2>Akhil Bhartiya Rander Parivar</h2>
    </div>
    <div class="avatar-wrapper">
      <div class="avatar">
        ${logo ? `<img src="${logo}" alt="${name}">` : '🏢'}
      </div>
    </div>
    <div class="content">
      <h1>${name}</h1>
      <span class="badge">${category}</span>
      <p class="desc">${desc}</p>

      <div class="info-list">
        ${owners ? `<div class="info-item"><strong>Owner:</strong> <span>${owners}</span></div>` : ''}
        ${city ? `<div class="info-item"><strong>City:</strong> <span>${city}</span></div>` : ''}
        ${address ? `<div class="info-item"><strong>Address:</strong> <span>${address}</span></div>` : ''}
        ${mobile ? `<div class="info-item"><strong>Contact:</strong> <span>${mobile}</span></div>` : ''}
      </div>

      <a href="abrp://business/${biz.id}" class="btn-open">
        📱 Open in ABRP App / ऐप में खोलें
      </a>

      <div>
        ${mobile ? `<a href="tel:${mobile}" class="btn-secondary">📞 Call Business</a>` : ''}
        ${mapsUrl ? `<a href="${mapsUrl}" target="_blank" class="btn-secondary">🗺️ View Map</a>` : ''}
        ${website ? `<a href="${website}" target="_blank" class="btn-secondary">🌐 Website</a>` : ''}
      </div>
    </div>
  </div>
  <p class="footer">Akhil Bhartiya Rander Parivar (ABRP) Samaj Portal</p>
</body>
</html>`;
}

function renderMemberPage(member: any, familyId: number, villageName: string): string {
  const name = escapeHtml(member.fullName);
  const photo = member.avatarUrl ? escapeHtml(member.avatarUrl) : '';
  const relation = escapeHtml(member.relationshipToHead || 'Member');
  const occupation = escapeHtml(member.occupationDetail || member.occupationType || '');
  const village = escapeHtml(villageName);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${name} | ABRP Member Profile</title>

  <!-- OpenGraph Metadata for WhatsApp / Facebook / Twitter -->
  <meta property="og:type" content="profile">
  <meta property="og:title" content="${name} - ABRP Samaj Profile">
  <meta property="og:description" content="View ${name}'s family tree & profile on Akhil Bhartiya Rander Parivar Samaj.">
  ${photo ? `<meta property="og:image" content="${photo}">` : ''}
  <meta property="og:url" content="https://abrp.vercel.app/member/${familyId}/${member.id}">
  <meta property="og:site_name" content="Akhil Bhartiya Rander Parivar">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #FDFBF7;
      color: #1F2937;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .card {
      background: #FFFFFF;
      border: 1px solid #E5E7EB;
      border-radius: 20px;
      max-width: 440px;
      width: 100%;
      box-shadow: 0 10px 30px rgba(0,0,0,0.06);
      overflow: hidden;
      text-align: center;
      padding-bottom: 24px;
    }
    .header-bar {
      background: linear-gradient(135deg, #1E3A8A, #3B82F6);
      color: #FFFFFF;
      padding: 24px 20px;
      text-align: center;
    }
    .header-bar h2 {
      font-family: 'Outfit', sans-serif;
      font-size: 16px;
      font-weight: 600;
      opacity: 0.9;
    }
    .avatar-wrapper {
      margin-top: -40px;
      margin-bottom: 12px;
      display: flex;
      justify-content: center;
    }
    .avatar {
      width: 88px;
      height: 88px;
      border-radius: 50%;
      background: #FFFFFF;
      border: 3px solid #3B82F6;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 36px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.12);
      overflow: hidden;
    }
    .avatar img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .content { padding: 0 24px; }
    h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 22px;
      color: #111827;
      margin-bottom: 4px;
    }
    .badge {
      display: inline-block;
      background: #DBEAFE;
      color: #1E40AF;
      font-size: 12px;
      font-weight: 600;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 16px;
    }
    .info-list {
      background: #F9FAFB;
      border-radius: 12px;
      padding: 12px 16px;
      text-align: left;
      font-size: 13px;
      color: #374151;
      margin-bottom: 24px;
    }
    .info-item {
      display: flex;
      margin-bottom: 6px;
    }
    .info-item:last-child { margin-bottom: 0; }
    .info-item strong { min-width: 90px; color: #6B7280; }
    .btn-open {
      display: block;
      background: linear-gradient(135deg, #1E3A8A, #3B82F6);
      color: #FFFFFF !important;
      text-decoration: none;
      font-family: 'Outfit', sans-serif;
      font-size: 16px;
      font-weight: 700;
      padding: 14px;
      border-radius: 12px;
      box-shadow: 0 4px 14px rgba(30, 58, 138, 0.3);
      transition: transform 0.15s ease;
    }
    .btn-open:active { transform: scale(0.98); }
    .footer { font-size: 12px; color: #9CA3AF; margin-top: 16px; }
  </style>

  <!-- Auto-launch App via Deep Link or Android Intent -->
  <script>
    (function() {
      var memberId = "${member.id}";
      var familyId = "${familyId}";
      var appUrl = "abrp://member/" + familyId + "/" + memberId;
      var isAndroid = /Android/i.test(navigator.userAgent);
      if (isAndroid) {
        window.location.href = "intent://member/" + familyId + "/" + memberId + "#Intent;scheme=abrp;package=com.abrp.mobile_app;end";
      } else if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        window.location.href = appUrl;
      }
    })();
  </script>
</head>
<body>
  <div class="card">
    <div class="header-bar">
      <h2>Akhil Bhartiya Rander Parivar</h2>
    </div>
    <div class="avatar-wrapper">
      <div class="avatar">
        ${photo ? `<img src="${photo}" alt="${name}">` : '👤'}
      </div>
    </div>
    <div class="content">
      <h1>${name}</h1>
      <span class="badge">${relation}</span>

      <div class="info-list">
        ${village ? `<div class="info-item"><strong>Village/City:</strong> <span>${village}</span></div>` : ''}
        ${occupation ? `<div class="info-item"><strong>Occupation:</strong> <span>${occupation}</span></div>` : ''}
      </div>

      <a href="abrp://member/${familyId}/${member.id}" class="btn-open">
        📱 Open Profile in ABRP App / प्रोफाइल खोलें
      </a>
    </div>
  </div>
  <p class="footer">Akhil Bhartiya Rander Parivar (ABRP) Samaj Portal</p>
</body>
</html>`;
}

function renderNotFoundPage(message: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Not Found | ABRP</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #FDFBF7;
      color: #374151;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      text-align: center;
      padding: 24px;
    }
    .box {
      background: #FFFFFF;
      border: 1px solid #E5E7EB;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    h2 { font-size: 20px; color: #DC2626; margin-bottom: 8px; }
    p { font-size: 14px; color: #6B7280; margin-bottom: 20px; }
    a {
      display: inline-block;
      background: #553D00;
      color: #FFFFFF;
      text-decoration: none;
      padding: 10px 20px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="box">
    <h2>Profile Not Found</h2>
    <p>${escapeHtml(message)}</p>
    <a href="abrp://">Open ABRP App</a>
  </div>
</body>
</html>`;
}

export { webRouter };
