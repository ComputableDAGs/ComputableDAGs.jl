using ComputableDAGs
import ComputableDAGs.bytes_to_human_readable

@test bytes_to_human_readable(0) == "0.0 B"
@test bytes_to_human_readable(1020) == "1020.0 B"
@test bytes_to_human_readable(1025) == "1.001 KiB"
@test bytes_to_human_readable(684235) == "668.2 KiB"
@test bytes_to_human_readable(86214576) == "82.22 MiB"
@test bytes_to_human_readable(9241457698) == "8.607 GiB"
@test bytes_to_human_readable(3218598654367) == "2.927 TiB"
