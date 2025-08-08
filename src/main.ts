import { invoke } from "@tauri-apps/api/core";

import {
    isPermissionGranted,
    requestPermission,
    sendNotification,
    Schedule,
    cancel,
} from "@tauri-apps/plugin-notification";

window.addEventListener("DOMContentLoaded", async () => {
    let permissionGranted = await isPermissionGranted();
    if (!permissionGranted) {
        const permission = await requestPermission();
        permissionGranted = permission === "granted";
    }

    if (permissionGranted) {
        const schedule = Schedule.interval({
            day: 1,
        });
        
        sendNotification({
            title: "Daily Task Reminder",
            body: "Don't forget to check your tasks for today!",
            schedule,
        });
    }
});
