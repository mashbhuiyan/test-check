module.exports = class Pagination {
    static getPageUrl(parsedUrl) {
        let url = [parsedUrl.pathname];
        if (parsedUrl.query) {
            url.push(parsedUrl.query.split('&').filter(x => !x.includes('page')).join('&'));
        }
        return url.join('?');
    }
}