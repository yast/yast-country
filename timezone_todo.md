## UI Inconsistencies

### Clock and Time Zone dialog

- `Other Settings...` leads to a `Change Date and Time` dialog - and you
  really can't do anything else there. So the menu item should be named
  such; maybe even simply `Change Date and Time`.

### Change Date and Time dialog

- In `Manually` there is a `Change the Time Now` checkbox. If you uncheck
  it the whole `Manually` item is grayed out - so what's the point?
  AFAICS this checkbox could be removed.

## Integration testing

When doing integration tests, verify that:

- the link `/etc/localtime` points to the correct timezone
- the 3rd line in `/etc/adjtime` is set correctly to either `UTC` or `LOCAL`
- `hwclock -rv` shows the correct time from hardware clock
- `date` shows the correct system time

Test that:

- switching timezones in UTC adjusts the `Date and Time` UI element
- switching timezones in local time does NOT change `Date and Time`
- toggling the checkbox in `Hardware Clock Set to UTC` correctly adjusts `Date and Time`
- the above three tests work correctly after going to `Other Settings...` and setting the time there
- the above three tests work correctly after going to `Other Settings...` and aborting the dialog
- while in the `Clock and Time Zone` dialog the system state is not changed
- ... but entering `Other Settings...` and changing the time there does change the system settings immediately and
  the `Clock and Time Zone` dialog reflects these changes
- as it happens the ncurses and qt UIs are different, so test both
- also, install mode and normal (in the running system) are not identical, so test both
- also, there are (s390) arch differences, so if you care, test that also

## Refactoring

- there are a lot of YCP remains (`Ops.XXX`)
- the wizard dialogs are basically two huge blobs in two functions
- the state is partly in the dialogs, partly in the Timezone object, which is really annoying
  when working with the code and makes it hard to test
- `timezone/dialogs.rb#SetTimezone`'s `changed_time` arg looks superfluous (is never used)
