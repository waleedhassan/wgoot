# App content — every declaration Play asks for

**Where:** Play Console → Policy and programmes → App content

Play will not let you promote a release to production until every item here is
green. Work down the list in order.

---

## 1. Privacy policy

| Field | Value |
| --- | --- |
| Privacy policy URL | *(your public URL for `privacy-policy.html`)* |

## 2. App access

| Question | Answer |
| --- | --- |
| Is all functionality available without special access? | **Yes — all functionality is available without restrictions** |

There is no login, no paywall, no region lock and no promo code. Reviewers can
open the app and immediately see every screen.

## 3. Ads

| Question | Answer |
| --- | --- |
| Does your app contain ads? | **No** |

No ads SDK is present. The listing will show no "Contains ads" badge.

## 4. Content ratings

See [`content-rating.md`](content-rating.md). Expected result: Everyone / PEGI 3.

## 5. Target audience and content

| Field | Value |
| --- | --- |
| Target age groups | **13–15, 16–17, 18 and over** |
| Is the app appealing to children? | **No** |

Reasoning: the app is a devotional utility for people who pray, which in
practice is teenagers and adults. Ticking any under-13 box pulls the app into
the **Designed for Families** programme, which adds a separate content policy,
an ads-SDK certification requirement and a stricter review. There is no reason
to opt into that here.

If you ever do target under-13, you must also re-check the Families Ads
programme requirements and the COPPA/GDPR-K obligations.

## 6. News app

| Question | Answer |
| --- | --- |
| Is your app a news app? | **No** |

## 7. COVID-19 contact tracing and status apps

| Question | Answer |
| --- | --- |
| Is your app a publicly available COVID-19 contact tracing or status app? | **No** |

## 8. Data safety

See [`data-safety.md`](data-safety.md). Summary: no data collected, no data
shared, no advertising ID.

## 9. Government apps

| Question | Answer |
| --- | --- |
| Is your app developed by or on behalf of a government? | **No** |

This is an independent app. It is not affiliated with any ministry of Islamic
affairs, and the listing does not claim official endorsement — which matters,
because Play treats implied government affiliation as impersonation.

## 10. Financial features

| Question | Answer |
| --- | --- |
| Does your app provide any financial features? | **No — my app doesn't provide any financial features** |

No lending, no payments, no crypto, no zakat calculator that moves money.

## 11. Health apps

| Question | Answer |
| --- | --- |
| Does your app have health features? | **No** |

Prayer times are religious observance, not health, wellness or medical content.

## 12. Advertising ID

| Question | Answer |
| --- | --- |
| Does your app use advertising ID? | **No** |

## 13. Sensitive permissions and APIs

The release manifest declares four permissions:

| Permission | Purpose | Play declaration needed? |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | Show the adhan alert | No |
| `RECEIVE_BOOT_COMPLETED` | Reschedule alerts after a reboot | No |
| `SCHEDULE_EXACT_ALARM` | Fire the adhan at the exact minute | See below |
| `VIBRATE` | Vibrate with the notification | No |

None is in Play's restricted set (all-files access, SMS or call log, background
location, package queries), so no declaration form is expected.

**On exact alarms.** `SCHEDULE_EXACT_ALARM` is granted by the user at runtime on
Android 13+, and Play's policy limits exact alarms to apps where precise timing
is a core, user-facing feature. This app qualifies squarely: an adhan that fires
four minutes late is a broken app. Two things already protect you here — the app
uses `SCHEDULE_EXACT_ALARM` rather than the alarm-clock-only `USE_EXACT_ALARM`,
and the scheduler falls back to inexact scheduling instead of failing when the
permission is refused.

If a justification is ever requested, use:

> Wqoot is a prayer times app. It notifies the user at the exact minute each of
> the five daily Islamic prayer times begins. These times are astronomically
> determined and change every day, and a late notification defeats the purpose
> of the app, which is to pray at the correct time. The app schedules only these
> five daily alerts and an optional user-configured reminder before each one. If
> the user declines the permission, the app degrades to inexact scheduling
> rather than losing the feature.

Play policy shifts. If the Console shows a declaration form that is not
described here, read what it actually asks before answering, and update this
file in the same session.

---

## Store settings that are not under App content

| Field | Value |
| --- | --- |
| App category | **Lifestyle** |
| Tags | prayer times, Islam, Hijri calendar, adhan |
| Contact email | *(the address you want shown publicly on the listing)* |
| Website | *(optional — your repo or a landing page)* |
| Default listing language | **Arabic (ar)** |
| Countries | Worldwide unless you have a reason to narrow it |
| Ads declaration on the listing | No ads |
| Content guidelines and US export laws | Both must be ticked before rollout |
