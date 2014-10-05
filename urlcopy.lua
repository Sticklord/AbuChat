
local _, ns = ...

-- Highlights URL

local find = string.find
local gsub = string.gsub

local PATTERN = '()(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
local DOMAINS = [[.ac.ad.ae.aero.af.ag.ai.al.am.an.ao.aq.ar.arpa.as.asia.at.au
   .aw.ax.az.ba.bb.bd.be.bf.bg.bh.bi.biz.bj.bm.bn.bo.br.bs.bt.bv.bw.by.bz.ca
   .cat.cc.cd.cf.cg.ch.ci.ck.cl.cm.cn.co.com.coop.cr.cs.cu.cv.cx.cy.cz.dd.de
   .dj.dk.dm.do.dz.ec.edu.ee.eg.eh.er.es.et.eu.fi.firm.fj.fk.fm.fo.fr.fx.ga
   .gb.gd.ge.gf.gh.gi.gl.gm.gn.gov.gp.gq.gr.gs.gt.gu.gw.gy.hk.hm.hn.hr.ht.hu
   .id.ie.il.im.in.info.int.io.iq.ir.is.it.je.jm.jo.jobs.jp.ke.kg.kh.ki.km.kn
   .kp.kr.kw.ky.kz.la.lb.lc.li.lk.lr.ls.lt.lu.lv.ly.ma.mc.md.me.mg.mh.mil.mk
   .ml.mm.mn.mo.mobi.mp.mq.mr.ms.mt.mu.museum.mv.mw.mx.my.mz.na.name.nato.nc
   .ne.net.nf.ng.ni.nl.no.nom.np.nr.nt.nu.nz.om.org.pa.pe.pf.pg.ph.pk.pl.pm
   .pn.post.pr.pro.ps.pt.pw.py.qa.re.ro.ru.rw.sa.sb.sc.sd.se.sg.sh.si.sj.sk
   .sl.sm.sn.so.sr.ss.st.store.su.sv.sy.sz.tc.td.tel.tf.tg.th.tj.tk.tl.tm.tn
   .to.tp.tr.travel.tt.tv.tw.tz.ua.ug.uk.um.us.uy.va.vc.ve.vg.vi.vn.vu.web.wf
   .ws.xxx.ye.yt.yu.za.zm.zr.zw]]

local tlds = { }
for tld in DOMAINS:gmatch('%w+') do
   tlds[tld] = true
end
local protocols = {[''] = 0, ['http://'] = 0, ['https://'] = 0, ['ftp://'] = 0}

local function ColorURL(text, url)
	return ' |H'..'url'..':'..tostring(url)..'|h'..'|cff0099FF'..tostring(url)..'|h|r '
end

local function ScanURL(frame, text, ...)
	for pos, url, prot, subd, tld, colon, port, slash, path in text:gmatch(PATTERN) do
		if protocols[prot:lower()] == (1 - #slash) * #path
			and (colon == '' or port ~= '' and port + 0 < 65536)
			and (tlds[tld:lower()] or tld:find'^%d+$' and subd:find'^%d+%.%d+%.%d+%.$'
			and math.max(tld, subd:match'^(%d+)%.(%d+)%.(%d+)%.$') < 256)
			and not subd:find'%W%W'
		then
			text = text:gsub(url, ColorURL(text, url))
		end
	end

	frame.add(frame, text,...)
end

local function EnableURLCopy()
	for _, v in pairs(CHAT_FRAMES) do
		local chat = _G[v]
		if (chat and not chat.hasURLCopy and (chat ~= 'ChatFrame2')) then
			chat.add = chat.AddMessage
			chat.AddMessage = ScanURL
			chat.hasURLCopy = true
		end
	end
end
hooksecurefunc('FCF_OpenTemporaryWindow', EnableURLCopy)

local orig = _G.ChatFrame_OnHyperlinkShow
function _G.ChatFrame_OnHyperlinkShow(frame, link, text, button)
	local type, value = link:match('(%a+):(.+)')
	if (type == 'url') then
		local editBox = _G[frame:GetName()..'EditBox']
		if (editBox) then
			editBox:Show()
			editBox:SetText(value)
			editBox:SetFocus()
			editBox:HighlightText()
		end
	else
		orig(self, link, text, button)
	end
end

ns.RegisterEvent("PLAYER_LOGIN", EnableURLCopy)