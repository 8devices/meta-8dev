# Only the QAIRT inference elements are wanted. smartvencbin is unused and pulls
# smart-venc-ctrl-algo; camera/camera-apps would collide with the oss recipe's
# libgstqticamsrc.so.
PACKAGECONFIG:remove:8dev-basic = "smartvencbin camera camera-apps"
