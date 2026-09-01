# Pagy setup (https://ddnexus.github.io/pagy/)

# Out-of-range page requests (e.g. ?page=99) render the last page instead
# of raising Pagy::OverflowError.
require "pagy/extras/overflow"

# 20 records per page everywhere. Pagy 9 renamed the old :items var to
# :limit (collection.offset/.limit based).
Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:overflow] = :last_page
