const utcDate = new Date();
const date1 = utcDate.toLocaleString("en-US", {
    timeZone: "America/Los_Angeles"
});
const date = new Date(date1);

const DATA = {
    lead_types: [
        {
            id: 1,
            name: 'home',
            created_at: date,
            updated_at: date
        },
        {
            id: 2,
            name: 'life',
            created_at: date,
            updated_at: date
        },
        {
            id: 3,
            name: 'health',
            created_at: date,
            updated_at: date
        },
        {
            id: 4,
            name: 'renters',
            created_at: date,
            updated_at: date
        },
        {
            id: 5,
            name: 'commercial',
            created_at: date,
            updated_at: date
        },
        {
            id: 6,
            name: 'auto',
            created_at: date,
            updated_at: date
        },
        {
            id: 7,
            name: 'medicare',
            created_at: date,
            updated_at: date
        },
        {
            id: 8,
            name: 'P&C Bundle',
            created_at: date,
            updated_at: date
        },
        {
            id: 9,
            name: 'motorcycle',
            created_at: date,
            updated_at: date
        }
    ],
    product_types: [
        {
            id: 1,
            name: 'clicks',
            created_at: date,
            updated_at: date
        },
        {
            id: 2,
            name: 'calls',
            created_at: date,
            updated_at: date
        },
        {
            id: 3,
            name: 'leads',
            created_at: date,
            updated_at: date
        },
        {
            id: 4,
            name: 'syndi clicks',
            created_at: date,
            updated_at: date
        },
        {
            id: 5,
            name: 'quote funnels',
            created_at: date,
            updated_at: date
        }
    ],
    days: [
        {
            id: 0,
            name: 'Sunday'
        },
        {
            id: 1,
            name: 'Monday'
        },
        {
            id: 2,
            name: 'Tuesday'
        },
        {
            id: 3,
            name: 'Wednesday'
        },
        {
            id: 4,
            name: 'Thursday'
        },
        {
            id: 5,
            name: 'Friday'
        },
        {
            id: 6,
            name: 'Saturday'
        }
    ],
};

class SettingsDataset {
    static getData() {
        return DATA;
    }
}

module.exports = SettingsDataset;
