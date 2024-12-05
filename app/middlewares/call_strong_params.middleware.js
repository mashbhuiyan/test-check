module.exports = StrongParams = (req, res, next) => {
    const params = req.body ? req.body.lead : {};
    const post = params.post;

    if (req.body.schema_validation_required && req.body.schema_validation_required === 'No') {
        return next();
    }

    if (!params.lead_type_id) {
        return response(res, 'lead_type_id');
    } else if (!params.contact) {
        return response(res, 'contact');
    } else if (!params.contact.zip) {
        return response(res, 'contact.zip');
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
