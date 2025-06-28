-- config.ld
new_type("event","Events",false,"Parameters","Returns")
--new_type("class","Types",false,"Parameters","Returns")
custom_tags = {
    { 'deprecated', hidden = true },
}
alias("enum", "table")
alias("class", "type")
alias("package", "local")
file = {
--'scriptutils.lua',
--'bit.lua',
--'..\\baked',
'..\\temp'
}