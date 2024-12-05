module.exports = StrongParams = (req, res, next) => {
    const params = req.body ? req.body.lead : {};
    const token_type = req.body.token_type;
    const post = params.post;

    if (req.body.schema_validation_required && req.body.schema_validation_required === 'No') {
        return next();
    }

    if (!params.ip_address) {
        return response(res, 'ip_address');
    } else if (!params.lead_type_id) {
        return response(res, 'lead_type_id');
    } else if (!params.device_type) {
        return response(res, 'device_type');
    } else if (!params.user_agent) {
        return response(res, 'user_agent');
    } else if (!params.aid && token_type === 'admin') {
        return response(res, 'aid');
    } else if (!params.cid && token_type === 'admin') {
        return response(res, 'cid');
    } else if (!params.device_type) {
        return response(res, 'device_type');
    } else if (!params.traffic_tier) {
        return response(res, 'traffic_tier');
    } else if (!params.contact) {
        return response(res, 'contact');
    } else if (!params.contact.zip) {
        return response(res, 'contact.zip');
    } else if (post && !params.contact.email) {
        return response(res, 'contact.email');
    } else if (post && !params.contact.primary_phone) {
        return response(res, 'contact.phone');
    } else if (post && params.contact.primary_phone.length < 10) {
        return invalidResponse(res, 'contact.phone');
    }
    next();
};

function response(res, requiredField) {
    return res.status(422).json({
        success: false,
        error: `Field ${requiredField} is required`
    });
}

function invalidResponse(res, invalidField) {
    return res.status(422).json({
        success: false,
        error: `Field ${invalidField} is invalid`
    });
}
