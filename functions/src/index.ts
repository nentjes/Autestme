import { initializeApp } from "firebase-admin/app";

initializeApp();

export { claimReward } from "./claimReward.js";
export { reconcileStuckClaims } from "./reconcileStuckClaims.js";
