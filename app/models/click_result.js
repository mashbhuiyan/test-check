module.exports = class ClickResult {
    click_ping_id = undefined;
    account_id = undefined;
    campaign_id = undefined;
    brand_id = undefined;
    ad_group_id = undefined;
    ad_id = undefined;
    title = undefined;
    description = undefined;
    click_url = undefined;
    tracking_url = undefined;
    logo_url = undefined;
    site_host = undefined;
    company_name = undefined;
    display_name = undefined;
    payout = undefined;
    est_payout = undefined;
    viewed = undefined;
    clicked = undefined;
    email_click = undefined;
    premium = undefined;
    term = undefined;
    position = undefined;
    response_partner_id = undefined;
    de_duped = undefined;
    excluded = undefined;
    carrier_id = undefined;
    click_id = undefined;
    fallback_url = undefined;
    device_type = undefined;
    zip = undefined;
    state = undefined;
    source_type_id = undefined;
    active_source = undefined;
    lead_type_id = undefined;
    match = undefined;
    opportunity = undefined;
    listing = undefined;
    aid = undefined;
    cid = undefined;
    pst_hour = undefined;
    pst_day = undefined;
    pst_week = undefined;
    pst_month = undefined;
    pst_quarter = undefined;
    pst_year = undefined;
    created_at = undefined;
    updated_at = undefined;
    mobile = undefined;
    clicked_at = undefined;
    pub_aid = undefined;
    pub_cid = undefined;
    insured = undefined;
    continuous_coverage = undefined;
    home_owner = undefined;
    gender = undefined;
    marital_status = undefined;
    consumer_age = undefined;
    education = undefined;
    credit_rating = undefined;
    military_affiliation = undefined;
    num_drivers = undefined;
    num_vehicles = undefined;
    violations = undefined;
    dui = undefined;
    accidents = undefined;
    license_status = undefined;
    first_name = undefined;
    last_name = undefined;
    phone = undefined;
    email = undefined;
    city = undefined;
    county = undefined;
    tobacco = undefined;
    major_health_conditions = undefined;
    life_coverage_type = undefined;
    life_coverage_amount = undefined;
    property_type = undefined;
    property_age = undefined;
    years_in_business = undefined;
    commercial_coverage_type = undefined;
    household_income = undefined;
    ip_address = undefined;
    col1 = undefined;
    col2 = undefined;
    col3 = undefined;
    col4 = undefined;
    col5 = undefined;
    disqualification_reason = undefined;
    partner_id = undefined;
    full_data = undefined;
    prefill_perc = undefined;
    missing_fields = undefined;
    pii = undefined;
    backfilled = undefined;
    upstream_bid = undefined;
    product_type_id = undefined;
    network_id = undefined;
    click_listing_id = undefined;
    non_rtb_data = {
        account_manager_id: undefined,
        sales_rep_id: undefined,
        billing_type_id: undefined,
        insurance_carrier_id: undefined
    };

    update(data, non_rtb) {
        Object.assign(this.non_rtb_data, non_rtb);
        return Object.assign(this, data);
    }

    attributes() {
        let tmp_obj = Object.assign({}, this);
        delete tmp_obj.non_rtb_data;
        return Object.keys(tmp_obj);
    }

    data() {
        let tmp_obj = Object.assign({}, this);
        delete tmp_obj.non_rtb_data;
        return Object.values(tmp_obj);
    }

    nonRtbAttributes() {
        return Object.keys(this.non_rtb_data);
    }

    nonRtbData() {
        return Object.values(this.non_rtb_data);
    }
}
