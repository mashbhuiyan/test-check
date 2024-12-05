const Airbrake = require("@airbrake/node");
module.exports = class ErrorHandler {
    constructor() {
        if (process.env.AIRBRAKE_PROJECT_ENV !== 'development' && typeof (process.env.AIRBRAKE_PROJECT_ENV) !== 'undefined') {
            this.airbrake = new Airbrake.Notifier({
                projectId: process.env.AIRBRAKE_PROJECT_ID,
                projectKey: process.env.AIRBRAKE_PROJECT_KEY,
                environment: process.env.AIRBRAKE_PROJECT_ENV
            });
        }
    }

    notify(error) {
        if (process.env.AIRBRAKE_PROJECT_ENV === 'development') {
            console.log(error);
        } else {
            this.airbrake.notify(error);
        }
    }
}
