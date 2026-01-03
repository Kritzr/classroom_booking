/**
 * Firebase Functions entry point
 */

// cloud functions for sending approval emails via SendGrid
const {setGlobalOptions} = require("firebase-functions");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const {defineString} = require("firebase-functions/params");
const {onRequest} = require("firebase-functions/v2/https");
const {GoogleGenerativeAI} = require("@google/generative-ai");
const sgMail = require("@sendgrid/mail");

// 🔹 Global options (ONLY ONCE)
setGlobalOptions({maxInstances: 10});

// 🔹 SendGrid setup
const SENDGRID_KEY = defineString("SENDGRID_KEY");
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

// cloud functions for gemini api calls
const GEMINI_KEY = defineString("GEMINI_API_KEY");
const genAI = new GoogleGenerativeAI(GEMINI_KEY.value());

// HTTPS trigger for Gemini chat
exports.chatWithGemini = onRequest(
    {cors: true},
    async (req, res) => {
      try {
        const {message} = req.body;

        const model = genAI.getGenerativeModel({
          model: "models/gemini-2.0-flash",
          systemInstruction: `
        You are a Classroom Booking Assistant.

              You must respond ONLY in valid JSON.
              Use double quotes only.
              No explanations. No markdown.

              If the user asks about room availability, extract:
              - roomId
              - date (YYYY-MM-DD)
              - start (HH:mm in 24-hour format)
              - end (HH:mm in 24-hour format)

              Example:
              {
                "roomId": "/rooms/CSE-AI",
                "date": "2025-12-29",
                "start": "12:30",
                "end": "13:00"
              }

              If the input is unclear:
              {"type":"msg","content":"Please specify room and time."}
      `,
        });

        const result = await model.generateContent(message);
        res.json({text: result.response.text()});
      } catch (e) {
        res.status(500).json({error: "Gemini failed"});
      }
    });

