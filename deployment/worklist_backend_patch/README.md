# Work List Backend Patch

This patch contains only the backend files required to deploy the Work List feature to the live Laravel app behind `pay.udharcard.shop`.

## Files included in the zip

- `laravel-backend/app/Http/Controllers/API/WorkListController.php`
- `laravel-backend/app/Models/WorkListItem.php`
- `laravel-backend/database/migrations/2026_08_03_010000_create_work_list_items_table.php`
- `laravel-backend/routes/api.php`
- `deployment/worklist_backend_patch/README.md`

## Recommended deployment flow

1. Upload the zip to your VPS with aaPanel file manager, SFTP, or `scp`.
2. Extract the zip into the Laravel project root so the relative paths overwrite the existing app files correctly.
3. Run the Laravel migration with `--force`.
4. Clear cached route/config state.
5. Verify the new routes are visible.

## Example VPS commands

Replace `APP_ROOT` with your real Laravel project path. Common aaPanel paths look like `/www/wwwroot/pay.udharcard.shop`.

```bash
cd APP_ROOT
unzip -o /path/to/worklist-backend-patch-2026-08-03.zip
php artisan migrate --force
php artisan route:clear
php artisan config:clear
php artisan cache:clear
php artisan optimize
php artisan route:list | grep work-list
```

## Safe pre-deploy backup

If you want a quick file backup before extraction:

```bash
cd APP_ROOT
cp routes/api.php routes/api.php.bak-2026-08-03
```

## Expected new endpoints

- `GET /api/merchant/work-list`
- `POST /api/merchant/work-list`
- `PUT /api/merchant/work-list/{id}`
- `DELETE /api/merchant/work-list/{id}`
- `GET /api/merchant/work-list/sync`
- `POST /api/merchant/work-list/sync`

## Post-deploy checks

```bash
cd APP_ROOT
php artisan route:list | grep work-list
tail -n 100 storage/logs/laravel.log
```

## Notes

- The migration creates a new `work_list_items` table with soft deletes.
- The controller uses the same merchant scoping fallback pattern already used in this repo: authenticated merchant first, then `X-Merchant-Id` for local or fallback flows.
- No `.env` change is required for this patch.