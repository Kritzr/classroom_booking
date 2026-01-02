/**
 * Firebase Functions entry point
 */

const {setGlobalOptions} = require("firebase-functions");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const {defineString} = require("firebase-functions/params");
// const functions = require("firebase-functions");
const sgMail = require("@sendgrid/mail");

const SENDGRID_KEY = defineString("SENDGRID_KEY");

// 🔹 Global options (ONLY ONCE)
setGlobalOptions({maxInstances: 10});

sgMail.setApiKey(SENDGRID_KEY.value());

// 🔔 Firestore trigger
exports.sendApprovalEmail = onDocumentUpdated(
    "event_letters/{docId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (!before || !after) return;

      // Only run if approvalStatus changed
      if (before.approvalStatus === after.approvalStatus) {
        return;
      }

      const status = after.approvalStatus;

      if (status !== "approved" && status !== "rejected") {
        return;
      }

      const userEmail = after.userEmail;
      const eventName = after.eventName || "your event";

      if (!userEmail) {
        logger.error("User email missing");
        return;
      }

      const msg = {
        to: userEmail,
        from: "neelavathysangeetha@gmail.com", // must be verified in SendGrid
        subject:
        status === "approved" ?
          "Your Event Letter Has Been Approved" :
          "Your Event Letter Has Been Rejected",
        text:
        status === "approved" ?
          `Your request for "${eventName}" has been approved.` :
          `Your request for "${eventName}" has been rejected.`,
      };

      try {
        await sgMail.send(msg);
        logger.info("Email sent to", userEmail);
      } catch (error) {
        logger.error("SendGrid error", error);
      }
    },
);
