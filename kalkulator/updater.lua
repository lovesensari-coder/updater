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
local FileOutputStream = luajava.bindClass("java.io.FileOutputStream")
local Array = luajava.bindClass("java.lang.reflect.Array")
local Byte = luajava.bindClass("java.lang.Byte")

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

local function downloadFileStream(urlStr, destPath)
    local url = URL(urlStr)
    local conn = url.openConnection()
    local inStream = conn.getInputStream()
    local outStream = FileOutputStream(destPath)
    local buffer = Array.newInstance(Byte.TYPE, 8192)
    local bytesRead = inStream.read(buffer)
    while bytesRead ~= -1 do
        outStream.write(buffer, 0, bytesRead)
        bytesRead = inStream.read(buffer)
    end
    outStream.flush()
    outStream.close()
    inStream.close()
    return true
end

Thread(Runnable({
    run = function()
        local success, result = pcall(fetchText, jsonUrl .. "?t=" .. tostring(os.time()))
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
                                alert.dismiss()
                                
                                local loadLayout = LinearLayout(ctx)
                                loadLayout.setOrientation(1)
                                loadLayout.setPadding(60, 60, 60, 60)
                                loadLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
                                
                                local loadText = TextView(ctx)
                                loadText.setText("Sedang mengunduh pembaruan...\nMohon tunggu.")
                                loadText.setTextSize(18)
                                loadText.setTextColor(Color.parseColor("#1F2937"))
                                loadText.setGravity(Gravity.CENTER)
                                loadLayout.addView(loadText)
                                
                                local loadDialog = AlertDialog.Builder(ctx)
                                loadDialog.setView(loadLayout)
                                loadDialog.setCancelable(false)
                                local loadAlert = loadDialog.create()
                                loadAlert.getWindow().setType(2032)
                                loadAlert.show()
                                local loadWindow = loadAlert.getWindow()
                                loadWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                                
                                Thread(Runnable({
                                    run = function()
                                        local dest = pluginDir .. "/main.lua"
                                        Thread.sleep(math.random(1000, 5000))
                                        local dlSuccess = pcall(downloadFileStream, downloadUrl .. "?t=" .. tostring(os.time()), dest)
                                        Handler(Looper.getMainLooper()).post(Runnable({
                                            run = function()
                                                loadAlert.dismiss()
                                                
                                                if dlSuccess then
                                                    local fv = io.open(pluginDir .. "/version.txt", "w")
                                                    if fv then
                                                        fv:write(latestVersion)
                                                        fv:close()
                                                    end
                                                    
                                                    local succLayout = LinearLayout(ctx)
                                                    succLayout.setOrientation(1)
                                                    succLayout.setPadding(60, 60, 60, 60)
                                                    succLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
                                                    
                                                    local succTitle = TextView(ctx)
                                                    succTitle.setText("Pembaruan Berhasil")
                                                    succTitle.setTextSize(24)
                                                    succTitle.setTextColor(Color.parseColor("#10B981"))
                                                    succTitle.setGravity(Gravity.CENTER)
                                                    local succTitleParams = LinearLayout.LayoutParams(-1, -2)
                                                    succTitleParams.setMargins(0, 0, 0, 20)
                                                    succTitle.setLayoutParams(succTitleParams)
                                                    succLayout.addView(succTitle)
                                                    
                                                    local succMsg = TextView(ctx)
                                                    succMsg.setText("Saat ini versi Anda sudah yang terbaru.")
                                                    succMsg.setTextSize(16)
                                                    succMsg.setTextColor(Color.parseColor("#1F2937"))
                                                    succMsg.setGravity(Gravity.CENTER)
                                                    local succMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                    succMsgParams.setMargins(0, 0, 0, 60)
                                                    succMsg.setLayoutParams(succMsgParams)
                                                    succLayout.addView(succMsg)
                                                    
                                                    local infoLayout = LinearLayout(ctx)
                                                    infoLayout.setOrientation(0)
                                                    local infoParams = LinearLayout.LayoutParams(-1, -2)
                                                    infoParams.setMargins(0, 0, 0, 60)
                                                    infoLayout.setLayoutParams(infoParams)
                                                    
                                                    local vInfo = TextView(ctx)
                                                    vInfo.setText("Versi saat ini:\n" .. latestVersion)
                                                    vInfo.setTextSize(14)
                                                    vInfo.setTextColor(Color.parseColor("#6B7280"))
                                                    vInfo.setGravity(Gravity.LEFT)
                                                    local vInfoParams = LinearLayout.LayoutParams(0, -2, 1)
                                                    vInfo.setLayoutParams(vInfoParams)
                                                    infoLayout.addView(vInfo)
                                                    
                                                    local dInfo = TextView(ctx)
                                                    dInfo.setText("Tanggal pembaruan:\n" .. os.date("%d/%m/%Y"))
                                                    dInfo.setTextSize(14)
                                                    dInfo.setTextColor(Color.parseColor("#6B7280"))
                                                    dInfo.setGravity(Gravity.RIGHT)
                                                    local dInfoParams = LinearLayout.LayoutParams(0, -2, 1)
                                                    dInfo.setLayoutParams(dInfoParams)
                                                    infoLayout.addView(dInfo)
                                                    
                                                    succLayout.addView(infoLayout)
                                                    
                                                    local footerMsg = TextView(ctx)
                                                    footerMsg.setText("Pembaharuan berhasil terpasang silakan muat ulang untuk menerapkan perubahan")
                                                    footerMsg.setTextSize(14)
                                                    footerMsg.setTextColor(Color.parseColor("#4B5563"))
                                                    footerMsg.setGravity(Gravity.CENTER)
                                                    local fMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                    fMsgParams.setMargins(0, 0, 0, 60)
                                                    footerMsg.setLayoutParams(fMsgParams)
                                                    succLayout.addView(footerMsg)
                                                    
                                                    local btnOk = Button(ctx)
                                                    btnOk.setText("Oke")
                                                    btnOk.setAllCaps(false)
                                                    btnOk.setTextColor(Color.parseColor("#FFFFFF"))
                                                    btnOk.setTextSize(18)
                                                    local btnOkBg = GradientDrawable()
                                                    btnOkBg.setColor(Color.parseColor("#10B981"))
                                                    btnOkBg.setCornerRadius(20)
                                                    btnOk.setBackgroundDrawable(btnOkBg)
                                                    
                                                    local succDialog = AlertDialog.Builder(ctx)
                                                    succDialog.setView(succLayout)
                                                    succDialog.setCancelable(false)
                                                    local succAlert = succDialog.create()
                                                    
                                                    btnOk.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                                                        onClick = function(v)
                                                            succAlert.dismiss()
                                                            pcall(function() ctx.restart() end)
                                                        end
                                                    }))
                                                    succLayout.addView(btnOk)
                                                    
                                                    succAlert.getWindow().setType(2032)
                                                    succAlert.show()
                                                    local succWindow = succAlert.getWindow()
                                                    succWindow.setLayout(-1, -1)
                                                    succWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                                                    succWindow.getDecorView().setPadding(0, 0, 0, 0)
                                                    
                                                else
                                                    local failLayout = LinearLayout(ctx)
                                                    failLayout.setOrientation(1)
                                                    failLayout.setPadding(60, 60, 60, 60)
                                                    failLayout.setBackgroundColor(Color.parseColor("#F3F4F6"))
                                                    
                                                    local failTitle = TextView(ctx)
                                                    failTitle.setText("Pembaruan gagal")
                                                    failTitle.setTextSize(24)
                                                    failTitle.setTextColor(Color.parseColor("#EF4444"))
                                                    failTitle.setGravity(Gravity.CENTER)
                                                    local failTitleParams = LinearLayout.LayoutParams(-1, -2)
                                                    failTitleParams.setMargins(0, 0, 0, 20)
                                                    failTitle.setLayoutParams(failTitleParams)
                                                    failLayout.addView(failTitle)
                                                    
                                                    local failMsg = TextView(ctx)
                                                    failMsg.setText("Mohon maaf, saat ini pembaruan tidak dapat dilakukan. Pastikan koneksi internet Anda stabil dan silakan coba lagi beberapa saat lagi.")
                                                    failMsg.setTextSize(16)
                                                    failMsg.setTextColor(Color.parseColor("#4B5563"))
                                                    failMsg.setGravity(Gravity.CENTER)
                                                    local failMsgParams = LinearLayout.LayoutParams(-1, -2)
                                                    failMsgParams.setMargins(0, 0, 0, 60)
                                                    failMsg.setLayoutParams(failMsgParams)
                                                    failLayout.addView(failMsg)
                                                    
                                                    local btnFailOk = Button(ctx)
                                                    btnFailOk.setText("Oke")
                                                    btnFailOk.setAllCaps(false)
                                                    btnFailOk.setTextColor(Color.parseColor("#FFFFFF"))
                                                    btnFailOk.setTextSize(18)
                                                    local btnFailBg = GradientDrawable()
                                                    btnFailBg.setColor(Color.parseColor("#3B82F6"))
                                                    btnFailBg.setCornerRadius(20)
                                                    btnFailOk.setBackgroundDrawable(btnFailBg)
                                                    
                                                    local failDialog = AlertDialog.Builder(ctx)
                                                    failDialog.setView(failLayout)
                                                    failDialog.setCancelable(false)
                                                    local failAlert = failDialog.create()
                                                    
                                                    btnFailOk.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
                                                        onClick = function(v)
                                                            failAlert.dismiss()
                                                        end
                                                    }))
                                                    failLayout.addView(btnFailOk)
                                                    
                                                    failAlert.getWindow().setType(2032)
                                                    failAlert.show()
                                                    local failWindow = failAlert.getWindow()
                                                    failWindow.setLayout(-1, -1)
                                                    failWindow.setBackgroundDrawable(ColorDrawable(Color.parseColor("#F3F4F6")))
                                                    failWindow.getDecorView().setPadding(0, 0, 0, 0)
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