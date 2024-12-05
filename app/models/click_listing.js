const ErrorHandler = require("./error_handler");
const Click = require("./click");
const errorHandler = new ErrorHandler();

module.exports = class ClickListing {
    constructor(brand_conf) {
        this.db = brand_conf.db;
        this.brand_conf = brand_conf;
    }

    async updateImpression(click_listing_id, position = null) {
        this.db.query(`select *
                       from click_listings
                       where id = ${click_listing_id}`, (error, results) => {
            if (error) {
                return error;
            } else {
                const click_listing = results.rows[0];
                if (click_listing) {
                    let click_result_data = {viewed: 1}
                    let set_data = `viewed = 1`
                    if (position) {
                        set_data += `, position = ${position}`;
                        click_result_data.position = position;
                    }
                    this.db.query(`update click_listings
                                   set ${set_data}
                                   where id = ${click_listing_id}`, (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                            console.log('impression updated failed');
                        } else {
                            //console.log('impression updated success');
                        }
                    });
                    if (click_listing.ping_post) {
                        (new Click(this.brand_conf, {}, [])).updateClickResult(click_listing.click_ping_id, click_listing.account_id, click_listing.campaign_id, click_listing.ad_group_id, click_result_data, click_listing.display_name);
                    } else {
                        (new Click(this.brand_conf, {}, [])).updateClickResult(click_listing.click_ping_id, click_listing.account_id, click_listing.campaign_id, click_listing.ad_group_id, click_result_data);
                    }
                }
            }
        });
    }
}
