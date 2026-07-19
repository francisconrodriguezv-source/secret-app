import * as functions from "firebase-functions/v1";
import {logger} from "firebase-functions/v1";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

// Nota: usamos Cloud Functions Gen 1 (`firebase-functions/v1`). Gen 2
// requiere permisos IAM específicos en service accounts (Cloud Run +
// Eventarc) que suelen fallar al primer deploy con "Failed to modify
// the IAM policy". Gen 1 no depende de eso; se ejecuta con la service
// account default de App Engine.

const REGION = "us-central1";

// ============================================================================
// Helpers
// ============================================================================

/**
 * Devuelve el uid del OTRO miembro del couple (distinto a excludeUid).
 * Retorna null si el couple todavía es de una sola persona (creador
 * esperando pareja).
 */
async function otherMemberUid(
  coupleId: string,
  excludeUid: string,
): Promise<string | null> {
  const membersSnap = await getFirestore()
    .collection("couples")
    .doc(coupleId)
    .collection("members")
    .get();
  for (const doc of membersSnap.docs) {
    if (doc.id !== excludeUid) return doc.id;
  }
  return null;
}

/**
 * Envía un push FCM al uid indicado, si tiene fcmToken registrado.
 * No lanza si falla — solo loguea. FCM puede fallar por tokens
 * expirados; no queremos que eso rompa la escritura al Firestore.
 */
async function sendPush(
  toUid: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  const userSnap = await getFirestore().collection("users").doc(toUid).get();
  const token = userSnap.data()?.fcmToken as string | undefined;
  if (!token) {
    logger.info(`No fcmToken for user ${toUid}, skipping push`);
    return;
  }
  try {
    await getMessaging().send({
      token,
      notification: {title, body},
      data,
      android: {
        priority: "high",
        notification: {
          channelId: "cozy_thinking",
        },
      },
    });
  } catch (err) {
    logger.error(`Failed to send push to ${toUid}:`, err);
  }
}

// ============================================================================
// Triggers (Cloud Functions Gen 1)
// ============================================================================

/**
 * Se dispara cuando un miembro crea un moment (foto o nota) en el
 * timeline. Envía push al otro miembro.
 */
export const onMomentCreated = functions
  .region(REGION)
  .firestore.document("couples/{coupleId}/moments/{momentId}")
  .onCreate(async (snap, context) => {
    const coupleId = context.params.coupleId as string;
    const data = snap.data();
    if (!data) return;
    const authorId = data.authorId as string;
    const authorName = (data.authorName as string) || "Tu pareja";
    const kind = data.kind as string;
    const caption = (data.caption as string) || "";
    const quote = (data.quote as string) || "";
    const otherUid = await otherMemberUid(coupleId, authorId);
    if (!otherUid) return;
    const title = `${authorName} 💗`;
    const body = kind === "photo"
      ? (caption || "te compartió una foto")
      : (quote.replace(/^"|"$/g, "") || "te dejó una nota");
    await sendPush(otherUid, title, body, {
      type: "moment",
      coupleId,
      momentId: context.params.momentId as string,
    });
  });

/**
 * Se dispara cuando un miembro pega una nota en el message board.
 * Envía push al otro miembro.
 */
export const onNoteCreated = functions
  .region(REGION)
  .firestore.document("couples/{coupleId}/notes/{noteId}")
  .onCreate(async (snap, context) => {
    const coupleId = context.params.coupleId as string;
    const data = snap.data();
    if (!data) return;
    const authorId = data.authorId as string;
    const authorName = (data.author as string) || "Tu pareja";
    const text = (data.text as string) || "";
    const otherUid = await otherMemberUid(coupleId, authorId);
    if (!otherUid) return;
    await sendPush(otherUid, `${authorName} 💌`, text || "te dejó una nota", {
      type: "note",
      coupleId,
      noteId: context.params.noteId as string,
    });
  });

/**
 * Se dispara cuando el usuario toca el corazón del top bar ("Pensando
 * en ti"). Envía push al otro miembro y borra el doc (no se preserva
 * historial de pokes).
 */
export const onPokeCreated = functions
  .region(REGION)
  .firestore.document("couples/{coupleId}/pokes/{pokeId}")
  .onCreate(async (snap, context) => {
    const coupleId = context.params.coupleId as string;
    const data = snap.data();
    if (!data) return;
    const fromUid = data.fromUid as string;
    const fromName = (data.fromName as string) || "Tu pareja";
    const otherUid = await otherMemberUid(coupleId, fromUid);
    if (otherUid) {
      await sendPush(otherUid, "Tandem 💗", `${fromName} está pensando en ti`, {
        type: "poke",
        coupleId,
      });
    }
    // Cleanup: el poke no se preserva.
    try {
      await snap.ref.delete();
    } catch (err) {
      logger.warn(`Failed to delete poke doc:`, err);
    }
  });
