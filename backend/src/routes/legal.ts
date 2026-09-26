import { Hono } from 'hono';
import { PRIVACY_POLICY, TERMS_AND_CONDITIONS, FAQS } from '../constants/legal.js';

const legalRouter = new Hono();

// GET /api/v1/legal/privacy-policy?lang=en|hi
legalRouter.get('/privacy-policy', (c) => {
  const lang = (c.req.query('lang') === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
  return c.json({
    language: lang,
    document: PRIVACY_POLICY[lang],
    allLanguages: {
      en: PRIVACY_POLICY.en,
      hi: PRIVACY_POLICY.hi,
    },
  });
});

// GET /api/v1/legal/terms-and-conditions?lang=en|hi
legalRouter.get('/terms-and-conditions', (c) => {
  const lang = (c.req.query('lang') === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
  return c.json({
    language: lang,
    document: TERMS_AND_CONDITIONS[lang],
    allLanguages: {
      en: TERMS_AND_CONDITIONS.en,
      hi: TERMS_AND_CONDITIONS.hi,
    },
  });
});

// GET /api/v1/legal/faqs?lang=en|hi
legalRouter.get('/faqs', (c) => {
  const lang = (c.req.query('lang') === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
  return c.json({
    language: lang,
    faqs: FAQS[lang],
    allLanguages: {
      en: FAQS.en,
      hi: FAQS.hi,
    },
  });
});

export { legalRouter };
