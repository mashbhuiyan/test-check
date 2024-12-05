const ErrorHandler = require("./error_handler");
const errorHandler = new ErrorHandler();
const Click = require('../../app/models/click');
const uuid = require("uuid");
const flatten = require("flat");
const util = require("./utils");

module.exports = class ClickEvent {
    update_event_schema = ['viewed', 'clicked', 'position', 'de_duped', 'excluded'];
    db = '';

    constructor(brand_conf, listing) {
        this.db = brand_conf.db;
        this.brand_conf = brand_conf;
        this.click_listing = listing;
    }

    async post(params, partner_id = '') {
        this.storeClickPost(params, partner_id);
        this.updatePingXml(this.click_listing.click_ping_id, params);
        this.regenerateClickUrl(params);
    }

    async regenerateClickUrl(params) {
        const f_params = flatten(params);
        f_params.age = util.getAge(f_params);
        const clickModel = new Click(this.brand_conf, f_params, []);
        let click_id = uuid.v4().replace(/-/g, '');
        const click_integration_data = {
            click_id: click_id,
            aid: this.click_listing.pub_aid || this.click_listing.aid,
            cid: this.click_listing.pub_cid || this.click_listing.cid,
            clk_cost: this.click_listing.payout
        }
        const query = `select cit.name                       as click_integration_type,
                              ci.dest_url                       click_dest_url,
                              case
                                  when c.is_campaign_level_tracking is true then ccs.fallback_url
                                  else cags.fallback_url end as fallback_url,
                              case
                                  when c.is_campaign_level_tracking is true then ccs.dest_url
                                  else cags.dest_url end     as dest_url,
                              cl.source_type_id,
                              c.name                         as campaign_name,
                              ag.ad_group_name
                       from click_listings cl
                                inner join ad_groups ag on cl.ad_group_id = ag.id
                                inner join campaigns c on cl.campaign_id = c.id
                                left join click_campaign_settings ccs on ccs.campaign_id = c.id
                                left join click_ad_group_settings cags on cags.ad_group_id = ag.id
                                left join click_integrations ci on ci.id = (case
                                                                                when c.is_campaign_level_tracking is true
                                                                                    then (case
                                                                                              when ccs.has_click_integration
                                                                                                  then ccs.click_integration_id
                                                                                              else null end)
                                                                                else (case
                                                                                          when cags.has_click_integration
                                                                                              then cags.click_integration_id
                                                                                          else null end) end)
                                left join click_integration_types cit on cit.id = ci.click_integration_type_id
                       where cl.id = ${this.click_listing.id}`;
        this.db.query(query, (error, results) => {
            if (error) {
                console.log('Re-Generate click_url campaign data query issue', error);
            } else {
                const campaign_data = results.rows[0];
                if (campaign_data) {
                    let campaign = clickModel.applyClickIntegration(campaign_data, click_integration_data);
                    campaign.click_listing_id = this.click_listing.id;
                    clickModel.click_listings[campaign.campaign_id] = campaign;
                    let click_url = clickModel.getMacroUrl(campaign.click_url, campaign);
                    if (click_url) {
                        this.updateClickUrl(click_url);
                    }
                }
            }
        });
    }

    async updatePingXml(ping_id, xml) {
        this.db.query(`select *
                       from click_pings
                       where id = ${ping_id}`, (error, results) => {
            if (!error) {
                let prev_xml = JSON.parse(results.rows[0]?.xml || '{}');
                let updated_xml = util.mergeDeep([prev_xml, xml]);
                this.db.query('update click_pings set xml = $2 where id = $1', [ping_id, updated_xml], (error, results) => {
                    if (error) {
                        console.log('Update ping xml query issue');
                    } else {
                        // console.log('Update ping xml successfully!');
                    }
                });
            }
        });
    }

    async storeClickPost(params, partner_id) {
        try {
            let current_date_time = new Date();
            let post_data = [partner_id, this.click_listing.click_ping_id, this.click_listing.id, this.click_listing.campaign_id, params, current_date_time, current_date_time];
            this.db.query('insert into click_posts (partner_id, click_ping_id, click_listing_id, campaign_id, data, created_at, updated_at) values($1, $2, $3, $4, $5, $6, $7)', post_data, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                } else {
                    console.log('Insert click post successfully!');
                }
            });
        } catch (ex) {
            errorHandler.notify(ex);
        }
    }

    async updateClickUrl(click_url) {
        this.db.query('update click_listings set click_url = $2 where id = $1', [this.click_listing.id, click_url], (error, results) => {
            if (error) {
                console.log('Update click listing click_url query issue');
            } else {
                // console.log('Update click listing click_url successfully!');
            }
        });
    }

    async updateClickListing(params) {
        return new Promise((resolve, reject) => {
            let click_result_data = {};
            let query = "update click_listings set ";
            let index = 1;
            let values = [];
            for (let field in params) {
                if (this.update_event_schema.includes(field)) {
                    query += field + '=$' + index + ',';
                    let value = params[field];
                    if (typeof (value) == "boolean") {
                        values.push(value ? 1 : 0);
                        click_result_data[field] = value ? 1 : 0;
                    } else {
                        values.push(value);
                        click_result_data[field] = value;
                    }
                    index += 1;
                }
            }
            if (index > 1) {
                query = query.slice(0, -1);
                query += ` where id = ${this.click_listing.id}`;
                this.db.query(query, values, (error, results) => {
                    if (error) {
                        errorHandler.notify(error);
                        resolve('post event failed');
                    } else {
                        resolve('post event success');
                    }
                });
                (new Click(this.brand_conf, {}, [])).updateClickResult(this.click_listing.click_ping_id, this.click_listing.account_id, this.click_listing.campaign_id, this.click_listing.ad_group_id, click_result_data, this.click_listing.display_name, this.click_listing.id);
            } else {
                resolve('post event failed');
            }
        });
    }

    async updateAdGroupAdLogic() {
        return new Promise((resolve, reject) => {
            this.db.query(`select ad_group_ads.*, ad_groups.account_id
                           from ad_group_ads
                                    inner join ad_groups on ad_group_ads.ad_group_id = ad_groups.id
                           where ad_group_id = ${this.click_listing.ad_group_id}
                             and ad_group_ads.discarded_at is null`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve([]);
                } else {
                    let ad_group_ads = results.rows;
                    for (const ad_group_ad of ad_group_ads) {
                        // disabling the processing as it is causing heavy load on DB
                        // if (ad_group_ad.weight_type === 'system_optimized') {
                        //     this.updateAdSystemOptimizedAdGroupAd(ad_group_ad).then(resp => {
                        //         console.log("System Optimized: ", resp);
                        //     });
                        // } else {
                        //     this.updateAdSplitEvenly(ad_group_ad).then(resp => {
                        //         console.log("split evenly: ", resp);
                        //     });
                        // }
                    }
                    resolve(ad_group_ads);
                }
            });
        });
    }

    async updateCampaignAdLogic() {
        return new Promise((resolve, reject) => {
            this.db.query(`select campaign_ads.*, campaigns.account_id
                           from campaign_ads
                                    inner join campaigns on campaign_ads.campaign_id = campaigns.id
                           where campaign_id = ${this.click_listing.campaign_id}
                             and campaign_ads.discarded_at is null`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                }
                let campaign_ads = results.rows;
                for (const campaign_ad of campaign_ads) {
                    // disabling the processing as it is causing heavy load on DB
                    // if (campaign_ad.weight_type === 'system_optimized') {
                    //     this.updateAdSystemOptimizedCampaignAd(campaign_ad).then(resp => {
                    //         // console.log("system optimized campaign ad: ", resp);
                    //     });
                    // } else {
                    //     this.updateAdSplitEvenlyCampaignAd(campaign_ad).then(resp => {
                    //         // console.log("split evenly campaign ad: ", resp);
                    //     });
                    // }
                }
                resolve(campaign_ads);
            });
        });
    }

    async updateAdSplitEvenly(ad_group_ad) {
        return new Promise((resolve, reject) => {
            this.db.query(`select count(*) total
                           from click_listings
                           where ad_id = ${ad_group_ad.ad_id}
                             and id in (select id
                                        from click_listings
                                        where account_id = ${ad_group_ad.account_id}
                                          and ad_group_id = ${ad_group_ad.ad_group_id}
                                          and viewed = 1
                                        order by id desc
                                        limit 10)`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    console.log(error);
                    resolve([]);
                } else {
                    let total = results.rows[0].total;
                    let value = (total * 100) / 10
                    this.updateAdGroupAdWeight(ad_group_ad.id, value).then(resp => {
                        resolve(resp);
                    });
                }
            });
        })
    }

    async updateAdSplitEvenlyCampaignAd(campaign_ad) {
        return new Promise((resolve, reject) => {
            this.db.query(`select count(*) total
                           from click_listings
                           where ad_id = ${campaign_ad.ad_id}
                             and id in (select id
                                        from click_listings
                                        where account_id = ${campaign_ad.account_id}
                                          and campaign_id = ${campaign_ad.campaign_id}
                                          and viewed = 1
                                        order by id desc
                                        limit 10)`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    console.log(error);
                    resolve([]);
                } else {
                    let total = results.rows[0].total;
                    let value = (total * 100) / 10
                    this.updateCampaignAdWeight(campaign_ad.id, value).then(resp => {
                        resolve(resp);
                    });
                }
            });
        })
    }

    async updateAdSystemOptimizedCampaignAd(campaign_ad) {
        return new Promise((resolve, reject) => {
            this.db.query(`select ad_id,
                                  case when SUM(viewed) = 0 then 0 else (SUM(clicked) / SUM(viewed)::FLOAT) end ctr,
                                  count(*)::INT                                                                 record
                           from click_listings
                           where id in (select id
                                        from click_listings
                                        where campaign_id = ${campaign_ad.campaign_id}
                                        order by id desc
                                        limit 100)
                           group by ad_id
                           order by ctr desc;`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve([]);
                } else {
                    let click_listings = results.rows;
                    let total_record = click_listings.map(listing => listing.record).reduce((n1, n2) => n1 + n2, 0);
                    if (total_record >= 100) {
                        console.log("System optimized campaign ad: ", click_listings);
                        if (click_listings[0].ad_id == campaign_ad.ad_id) {
                            this.updateCampaignAdWeight(campaign_ad.id, -1).then(resp => {
                                resolve(resp);
                            });
                        }
                    } else {
                        resolve([]);
                    }
                }
            });
        })
    }

    async updateAdSystemOptimizedAdGroupAd(ad_group_ad) {
        return new Promise((resolve, reject) => {
            this.db.query(`select ad_id,
                                  case when SUM(viewed) = 0 then 0 else (SUM(clicked) / SUM(viewed)::FLOAT) end ctr,
                                  count(*)::INT                                                                 record
                           from click_listings
                           where id in (select id
                                        from click_listings
                                        where ad_group_id = ${ad_group_ad.ad_group_id}
                                        order by id desc
                                        limit 100)
                           group by ad_id
                           order by ctr desc;`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve([]);
                } else {
                    let click_listings = results.rows;
                    let total_record = click_listings.map(listing => listing.record).reduce((n1, n2) => n1 + n2, 0);
                    if (total_record >= 100) {
                        console.log("System optimized ad group ad: ", click_listings);
                        if (click_listings[0].ad_id == ad_group_ad.ad_id) {
                            this.updateAdGroupAdWeight(ad_group_ad.id, -1).then(resp => {
                                resolve(resp);
                            });
                        }
                    } else {
                        resolve([]);
                    }
                }
            });
        })
    }

    async updateAdGroupAdWeight(ad_group_ad_id, value) {
        return new Promise((resolve, reject) => {
            // console.log('Update weight: ', value);
            this.db.query(`update ad_group_ads
                           set active_weight = ${value}
                           where id = ${ad_group_ad_id}`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve('failed')
                } else {
                    resolve('success')
                }
            });
        });
    }

    async updateCampaignAdWeight(campaign_ad_id, value) {
        return new Promise((resolve, reject) => {
            // console.log('Update weight: ', value);
            this.db.query(`update campaign_ads
                           set active_weight = ${value}
                           where id = ${campaign_ad_id}`, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve('failed')
                } else {
                    resolve('success')
                }
            });
        });
    }
}
