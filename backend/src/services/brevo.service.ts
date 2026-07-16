import dotenv from 'dotenv';

dotenv.config();

export const brevoService = {
  /**
   * Sends a transactional email using Brevo SMTP REST API.
   * @param toEmail Recipient email address
   * @param toName Recipient name
   * @param subject Email subject line
   * @param htmlContent HTML body content
   */
  async sendEmail(toEmail: string, toName: string, subject: string, htmlContent: string) {
    const apiKey = process.env.BREVO_API_KEY;
    const senderEmail = process.env.BREVO_SENDER_EMAIL;
    const senderName = process.env.BREVO_SENDER_NAME;

    if (!apiKey) {
      console.warn('Brevo API Key is missing in environment variables. Email sending skipped.');
      return false;
    }

    try {
      const response = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'accept': 'application/json',
          'api-key': apiKey,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          sender: {
            name: senderName || 'Akhil Bhartiya Rander Parivar',
            email: senderEmail || 'no-reply@randerparivar.com',
          },
          to: [
            {
              email: toEmail,
              name: toName,
            },
          ],
          subject,
          htmlContent,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Brevo SMTP API returned error status:', response.status, errorText);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Failed to send email via Brevo:', error);
      return false;
    }
  },
};
