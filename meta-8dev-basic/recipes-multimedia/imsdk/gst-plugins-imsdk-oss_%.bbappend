# The "ml" and "tflite" element sets are gated because they drag in opencv/cairo/
# eigen and LiteRT. Native HTP inference lives in -prop.
PACKAGECONFIG:append:8dev-basic = " camera camera-apps"
PACKAGECONFIG:append:8dev-basic = " ${@bb.utils.contains('DISTRO_FEATURES', 'qnn', 'ml tflite', '', d)}"
PACKAGECONFIG:remove:8dev-basic = "messaging python-apps redissink sample-apps"
