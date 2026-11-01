local ctx, currentVersion, pluginDir = ...
local jsonUrl = "https://raw.githubusercontent.com/lovesensari-coder/updater/main/kalkulator/update.json"

local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local TextView = luajava.bindClass("android.widget.TextView")
local Button = luajava.bindClass("android.widget.Button")
local Gravity = luajava.bindClass("android.view.Gravity")
local AlertDialog = luajava.bindClass("android.app.AlertDialog")
local Color = luajava.bindClass("android.graphics.Color")
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
local Thread = luajava.bindClass("java.lang.Thread")
local Runnable = luajava.bindClass("java.lang.Runnable")
local URL = luajava.bindClass("java.net.URL")
local InputStreamReader = luajava.bindClass("java.io.InputStreamReader")
local BufferedReader = luajava.bindClass("java.io.BufferedReader")
local Handler = luajava.bindClass("android.os.Handler")
local Looper = luajava.bindClass("android.os.Looper")
local Toast = luajava.bindClass("android.widget.Toast")

local function fetchText(urlStr)
    local url = URL(urlStr)
    local conn = url.openConnection()
    local reader = BufferedReader(InputStreamReader(conn.getInputStream()))
    local content = ""
    local line = reader.readLine()
    while line do
        content = content .. line .. "\n"
        line = reader.readLine()
    end
    reader.close()
    return content
end

Thread(Runnable({
    run = function()
        local success, result = pcall(fetchText, jsonUrl)
        if success and result and result ~= "" then
            local latestVersion = string.match(result, '"latest_version"%s*:%s*"(.-)"')
            local changelog = string.match(result, '"changelog"%s*:%s*"(.-)"')
            local downloadUrl = string.match(result, '"download_url"%s*:%s*"(.-)"')
            
            if latestVersion and latestVersion ~= currentVersion then
                changelog = string.gsub(changelog, "\\n", "\n")
                
                Handler(Looper.getMainLooper()).post(Runnable({
                    run = function()
                        local layout = LinearLayout(ctx)
                        layout.setOrientation(1)
                        layout.setPadding(60, 60, 60, 60)
                        layout.setBackgroundColor(Color.parseColor("#F3F4F6"))
                        layout.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
                        
                        local title = TextView(ctx)
                        title.setText("Update Tersedia")
                        title.setTextSize(24)
                        title.setTextColor(Color.parseColor("#1F2937"))
                        title.setGravity(Gravity.CENTER)
                        local titleParams = LinearLayout.LayoutParams(-1, -2)
                        titleParams.setMargins(0, 0, 0, 20)
                        title.setLayoutParams(titleParams)
                        layout.addView(title)
                        
                        local subtitle = TextView(ctx)
                        subtitle.setText("Perbarui ke versi terbaru untuk pengalaman yang lebih baik")
                        subtitle.setTextSize(14)
                        subtitle.setTextColor(Color.parseColor("#6B7280"))
                        subtitle.setGravity(Gravity.CENTER)
                        local subParams = LinearLayout.LayoutParams(-1, -2)
                        subParams.setMargins(0, 0, 0, 60)
                        subtitle.setLayoutParams(subParams)
                        layout.addView(subtitle)
                        
                        local versionLayout = LinearLayout(ctx)
                        versionLayout.setOrientation(0)
                        local vParams = LinearLayout.LayoutParams(-1, -2)
                        vParams.setMargins(0, 0, 0, 60)
                        versionLayout.setLayoutParams(vParams)
                        
                        local vCurrent = TextView(ctx)
                        vCurrent.setText("Versi saat ini:\n" .. currentVersion)
                        vCurrent.setTextSize(14)
                        vCurrent.setTextColor(Color.parseColor("#6B7280"))
                        vCurrent.setGravity(Gravity.LEFT)
                        local vcParams = LinearLayout.LayoutParams(0, -2, 1)
                        vCurrent.setLayoutParams(vcParams)
                        versionLayout.addView(vCurrent)
                        
                        local vLatest = TextView(ctx)
                        vLatest.setText("Versi terbaru:\n" .. latestVersion)
                        vLatest.setTextSize(14)
                        vLatest.setTextColor(Color.parseColor("#10B981"))
                        vLatest.setGravity(Gravity.RIGHT)
                        local vlParams = LinearLayout.LayoutParams(0, -2, 1)
                        vLatest.setLayoutParams(vlParams)
                        versionLayout.addView(vLatest)
                        
                        layout.addView(versionLayout)
                        
                        local whatsNewTitle = TextView(ctx)
                        whatsNewTitle.setText("Apa yang baru:")
                        whatsNewTitle.setTextSize(16)
                        whatsNewTitle.setTextColor(Color.parseColor("#1F2937"))
                        local wntParams = LinearLayout.LayoutParams(-1, -2)
                        wntParams.setMargins(0, 0, 0, 10)
                        whatsNewTitle.setLayoutParams(wntParams)
                        layout.addView(whatsNewTitle)
                        
                        local whatsNew = TextView(ctx)
                        whatsNew.setText(changelog)
                        whatsNew.setTextSize(14)
                        whatsNew.setTextColor(Color.parseColor("#4B5563"))
                        local wnParams = LinearLayout.LayoutParams(-1, -2)
                        wnParams.setMargins(0, 0, 0, 80)
                        whatsNew.setLayoutParams(wnParams)
                        layout.addView(whatsNew)
                        
                        local dialog = AlertDialog.Builder(ctx)
                        dialog.setView(layout)
                        dialog.setCancelable(false)
                        local alert = dialog.create()
                        
                        local btnUpdate = Button(ctx)
                        btnUpdate.setText("Perbarui")
                        btnUpdate.setAllCaps(false)
                        btnUpdate.setTextColor(Color.parseColor("#FFFFFF"))
                        btnUpdate.setTextSize(18)
                        local btnUpBg = GradientDrawable()
                        btnUpBg.setColor(Color.parseColor("#3B82F6"))
                        btnUpBg.setCornerRadius(20)
                        btnUpdate.setBackgroundDrawable(btnUpBg)
                        local btnUpParams = LinearLayout.LayoutParams(-1, -2)
                        btnUpParams.setMargins(0, 0, 0, 30)
                        btnUpdate.setLayoutParams(btnUpParams)
                        
                        btnUpdate.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                            onClick = function(v)
                                Toast.makeText(ctx, "Mengunduh pembaruan...", 1).show()
                                Thread(Runnable({
                                    run = function()
                                        local dlSuccess, dlResult = pcall(fetchText, downloadUrl)
                                        Handler(Looper.getMainLooper()).post(Runnable({
                                            run = function()
                                                if dlSuccess and dlResult and dlResult ~= "" then
                                                    local f = io.open(pluginDir .. "/main.lua", "w")
                                                    if f then
                                                        f:write(dlResult)
                                                        f:close()
                                                        Toast.makeText(ctx, "Pembaruan berhasil. Silakan mulai ulang alat.", 1).show()
                                                        alert.dismiss()
                                                    else
                                                        Toast.makeText(ctx, "Gagal menyimpan pembaruan.", 1).show()
                                                    end
                                                else
                                                    Toast.makeText(ctx, "Gagal mengunduh pembaruan.", 1).show()
                                                end
                                            end
                                        }))
                                    end
                                })).start()
                            end
                        }))
                        layout.addView(btnUpdate)
                        
                        local btnCancel = Button(ctx)
                        btnCancel.setText("Lain kali")
                        btnCancel.setAllCaps(false)
                        btnCancel.setTextColor(Color.parseColor("#EF4444"))
                        btnCancel.setTextSize(18)
                        local btnCanBg = GradientDrawable()
                        btnCanBg.setColor(Color.parseColor("#00000000"))
                        btnCancel.setBackgroundDrawable(btnCanBg)
                        local btnCanParams = LinearLayout.LayoutParams(-1, -2)
                        btnCancel.setLayoutParams(btnCanParams)
                        
                        btnCancel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                            onClick = function(v)
                                alert.dismiss()
                            end
                        }))
                        layout.addView(btnCancel)
                        
                        alert.getWindow().setType(2032)
                        alert.show()
                        local window = alert.getWindow()
                        window.setLayout(-1, -1)
                        window.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                        window.getDecorView().setPadding(0, 0, 0, 0)
                    end
                }))
            end
        end
    end
})).start()