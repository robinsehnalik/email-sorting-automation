# Streamlined Email Triage & Native In-Thread Drafting — Implementation Guide

## 1. System Overview

The **Streamlined Email Triage Automation** provides high-speed inbox triage and grounded draft generation directly within Google Workspace / Gmail.

* **Non-Destructive Pre-Filtering**: Inbound messages are evaluated in strict priority order. Verified invoices from known partners are routed to billing, while newsletters and authentication warnings are labeled rather than silently archived.
* **Invoice-Fraud Guard**: Only pre-verified billing providers with valid authentication dispatch to the billing webhook. Unverified vendor invoices are flagged for human inspection (`Bills-Review`).
* **Dual-Label Support Queues**: Inquiries covered by policy receive in-thread drafts labeled `AI-Drafted` (agent reviews and sends). Inquiries requiring custom replies are labeled `Needs-Manual-Reply`.

```
[Inbound Email in Gmail]
           │
           ▼
[MAIL-01 Triage Pipeline]
           │
           ├────────────► [Pre-Filter Match?] ──(Yes)──┐
           │                                          │
           ▼ (No: Run LLM)                            ▼
[Single-Pass gpt-4o Structured JSON]         [Category & Security Router]
           │                                          │
           └──────────────────────────────────────────┤
                                                      ▼
                      ┌──────────────┬────────────────┼──────────────┬──────────────┐
                      ▼              ▼                ▼              ▼              ▼
              [Bills (Verified)] [Bills-Review]    [Sales]     [AI-Newsletter]  [Support]
                      │              │                │              │              │
                      ▼              ▼                ▼              ▼              ▼
                [Billing API]  [Human Check]    [CRM Webhook] [Labeled Inbox] [Requires Draft?]
                                                                                    │
                                                                   ┌────────────────┴────────────────┐
                                                                   ▼                                 ▼
                                                            [AI-Drafted]                   [Needs-Manual-Reply]
                                                            (Review & Send)                 (Write from Scratch)
```

---

## 2. Gmail Label Taxonomy

Create the following labels in your Google Workspace / Gmail account:

| Label Name | Purpose | Action Required |
| :--- | :--- | :--- |
| `AI-Drafted` | An in-thread draft has been generated using company policies. | Open thread, review draft, make edits if desired, click **Send**. |
| `Needs-Manual-Reply` | Inquiries requiring custom human responses or lacking policy context. | Open thread, compose response manually, click **Send**. |
| `Bills` | Verified vendor invoices from authenticated partners. | Automatically dispatched to Billing Automation; archive after verification. |
| `Bills-Review` | Unverified vendor invoices from general/unknown domains. | Inspect invoice authenticity before manually ingesting into accounting. |
| `Sales` | Inbound commercial leads and wholesale pricing inquiries. | Automatically dispatched to CRM; follow up via sales process. |
| `AI-Newsletter` | Automated marketing newsletters and bulk distributions. | Periodically review; bulk archive as needed. |
| `Auth-Warning` | Senders failing SPF/DKIM authentication checks. | Inspect for potential spoofing/phishing attempts. |
| `AI-Processed` | Applied to all emails once evaluated by the pipeline. | Idempotency marker preventing duplicate drafts or repeated processing. |

---

## 3. Environment Variables Configuration

Configure these environment variables in your n8n `.env` file:

| Variable | Description |
| :--- | :--- |
| `OPENAI_API_KEY` | OpenAI API key with access to `gpt-4o` |
| `LINK_TO_YOUR_N8N_INSTANCE` | Base URL of your n8n instance |
| `BILLING_WEBHOOK_SECRET` | Shared secret header (`X-Webhook-Secret`) to authenticate the billing webhook |
| `CRM_WEBHOOK_SECRET` | Shared secret header (`X-Webhook-Secret`) to authenticate CRM lead intake |
| `LINK_TO_YOUR_CRM_OR_LEAD_WEBHOOK` | Target endpoint for qualified sales leads |
| `LINK_TO_YOUR_SUPABASE_URL` | Supabase API endpoint (e.g. `https://xyz.supabase.co`) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key for telemetry insertion |
| `RESEND_API_KEY` | Resend API key for administrative incident alerting |
| `SYSTEM_SENDER_EMAIL` | Verified sending address for system alerts |
| `ADMIN_NOTIFICATION_EMAIL` | Destination mailbox for critical pipeline errors |

---

## 4. Google Workspace OAuth Setup

1. Open **Google Cloud Console** > **APIs & Services**.
2. Configure your OAuth Consent Screen as **Internal** (restricted to users within your Google Workspace organization).
3. Enable the **Gmail API**.
4. Request the scope: `https://www.googleapis.com/auth/gmail.modify` (permits reading, labeling, and draft creation).
5. Create an **OAuth 2.0 Client ID** (Web Application), set the authorized redirect URI from your n8n credentials screen, and connect.
