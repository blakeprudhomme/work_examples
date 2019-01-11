### Requested report with:
- All stores for all active accounts
- exclude any stores whose name match the format xxxx-xxxx-xxxx-xxxx
- show the qty of the store's cars/vans/trucks?
- each store's account's subdomain
- the number of vehicles in the store's account
- the number of vehicles in the store

```sql
SELECT s.name AS 'Store Name',
       s.slug AS 'Store Slug',
       a.subdomain AS 'Subdomain',
       a.vehicles_count AS 'Account Count',
       s.vehicles_count AS 'Store Count',
       Car.StoreCarCount AS "Cars",
       Van.StoreVanCount AS "Vans",
       Truck.StoreTruckCount AS "Trucks"
FROM stores AS s
  INNER JOIN accounts AS a
          ON s.account_id = a.id
  LEFT OUTER JOIN (
    SELECT store_id, COUNT(*) AS StoreCarCount
    FROM vehicles WHERE type = "car"
    GROUP BY store_id
  ) AS Car ON s.uid = Car.store_id
  LEFT OUTER JOIN (
    SELECT store_id, COUNT(*) AS StoreVanCount
    FROM vehicles WHERE type = "van"
    GROUP BY store_id
  ) AS Van ON s.uid = Van.store_id
  LEFT OUTER JOIN (
    SELECT store_id, COUNT(*) AS StoreTruckCount
    FROM vehicles WHERE type = "truck"
    GROUP BY store_id
  ) AS Truck ON s.uid = Truck.store_id
WHERE a.active = true
AND s.name NOT REGEXP '^[A-Z0-9][A-Z0-9][A-Z0-9-][A-Z0-9-]-[A-Z0-9-][A-Z0-9-][A-Z0-9-][A-Z0-9-]-[A-Z0-9-][A-Z0-9-][A-Z0-9-][A-Z0-9-]-[A-Z0-9-][A-Z0-9-][A-Z0-9-][A-Z0-9-]'
GROUP BY s.name
ORDER BY a.subdomain;
```
