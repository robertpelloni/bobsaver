#version 420

// original https://www.shadertoy.com/view/NsSSRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Wolfram Language Color Schemes (least square fitting)

// Apply least square fitting to color images downloaded from
// https://reference.wolfram.com/language/guide/ColorSchemes.html

// Each color scheme is fitted to three functions:

// `poly`: Polynomial functions of varying degree;
// `trig`: Functions in the form color(x)=c₀+c₁⋅x+a₀⋅cos(π⋅x-u₀)+∑ₖ[aₖ⋅cos(2kπ⋅x-uₖ)];
// `cosine`: Functions in the form color(t)=a+b*t+c*cos(d*t+e), inspired by iq's cosine color palette article;

// Coefficients for `cosine` are computed numerically and may not be optimal. 

// For a better visual and a comparison of the three color functions,
// go to https://harry7557558.github.io/Graphics/UI/color_functions/

// Disclaimer: I’m not related to Wolfram in anyway. Wolfram reserves the rights of these color schemes.

#define clp(x) clamp(x,0.,1.)

/* ====================== polynomial color functions ====================== */

vec3 AlpineColors_poly(float t) {
  float r = ((-.4622*t+1.3045)*t-.1249)*t+.2923;
  float g = ((.704*t-.5534)*t+.5138)*t+.36;
  float b = ((((9.8887*t-27.3837)*t+26.4292)*t-9.1505)*t+.6797)*t+.471;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LakeColors_poly(float t) {
  float r = ((.1712*t-.4642)*t+.9553)*t+.2824;
  float g = ((((2.6778*t-5.9178)*t+4.0214)*t-1.598)*t+1.6854)*t+.0398;
  float b = (((((14.3331*t-49.92)*t+67.0375)*t-42.1675)*t+10.8375)*t+.1711)*t+.5435;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ArmyColors_poly(float t) {
  float r = (((1.541*t-2.8123)*t+1.7038)*t-.1004)*t+.4553;
  float g = ((((-8.3474*t+20.6422)*t-16.9988)*t+5.4954)*t-.6404)*t+.6088;
  float b = ((.3088*t+.1844)*t-.3162)*t+.4933;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 MintColors_poly(float t) {
  float r = ((-.0409*t-.517)*t+1.0114)*t+.4574;
  float g = ((-.0395*t-.3079)*t-.0154)*t+.9762;
  float b = ((-.024*t-.5145)*t+.6901)*t+.6322;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AtlanticColors_poly(float t) {
  float r = ((((-11.4841*t+27.744)*t-24.019)*t+8.1684)*t-.1046)*t+.1426;
  float g = ((((-9.5585*t+25.2482)*t-24.7983)*t+9.4515)*t-.0451)*t+.1733;
  float b = ((((-9.0879*t+23.8016)*t-23.6116)*t+9.3791)*t-.0636)*t+.1775;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 NeonColors_poly(float t) {
  float r = ((-.4831*t+.398)*t+.1537)*t+.7183;
  float g = ((((((-80.4505*t+303.5468)*t-444.5506)*t+314.1646)*t-108.1716)*t+17.3104)*t-2.5901)*t+.9486;
  float b = (((((24.2125*t-76.6195)*t+88.8459)*t-45.0026)*t+9.9107)*t-.8773)*t+.3127;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AuroraColors_poly(float t) {
  float r = ((((-7.4062*t+25.1392)*t-29.1402)*t+13.7546)*t-1.7482)*t+.2757;
  float g = ((((12.7806*t-29.1753)*t+18.4877)*t-1.6536)*t-.4259)*t+.2602;
  float b = (((-8.7225*t+17.4175)*t-10.1037)*t+2.1106)*t+.2407;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PearlColors_poly(float t) {
  float r = (((-4.2707*t+10.5404)*t-7.1502)*t+.9435)*t+.8928;
  float g = (((-4.241*t+10.443)*t-7.6471)*t+1.4393)*t+.819;
  float b = (((-6.5327*t+14.1208)*t-9.0414)*t+1.6647)*t+.7584;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AvocadoColors_poly(float t) {
  float r = (((((-7.603*t+27.8647)*t-38.8095)*t+23.7046)*t-4.3474)*t+.1928)*t+.0001;
  float g = ((1.0364*t-2.339)*t+2.3265)*t-.0308;
  float b = ((.439*t-.6321)*t+.4378)*t-.0082;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PlumColors_poly(float t) {
  float r = ((3.1899*t-4.9201)*t+2.6995)*t-.028;
  float g = ((.8032*t-.4051)*t+.5155)*t-.0051;
  float b = ((-1.9967*t+2.234)*t+.1727)*t+.0033;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BeachColors_poly(float t) {
  float r = (((4.5546*t-6.3043)*t+1.9279)*t+.0068)*t+.8567;
  float g = (((3.9403*t-5.4029)*t+1.1958)*t+.8023)*t+.4998;
  float b = (((-4.6235*t+7.5264)*t-2.6001)*t+.4239)*t+.2536;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RoseColors_poly(float t) {
  float r = (((((-18.7367*t+56.7665)*t-60.4967)*t+25.4334)*t-3.811)*t+1.3969)*t+.1422;
  float g = (((4.0569*t-8.7696)*t+4.8136)*t-.2871)*t+.3237;
  float b = (((2.7654*t-5.7281)*t+2.6502)*t+.3314)*t+.0943;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CandyColors_poly(float t) {
  float r = ((((-7.2842*t+20.8882)*t-19.6045)*t+5.368)*t+.8857)*t+.4102;
  float g = (((1.4925*t-4.3903)*t+4.1011)*t-.5424)*t+.2222;
  float b = ((-2.0219*t+2.8582)*t-.3195)*t+.3518;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SolarColors_poly(float t) {
  float r = ((.8836*t-2.29)*t+1.9664)*t+.4404;
  float g = ((-1.156*t+1.8728)*t+.0831)*t+.0119;
  float b = ((-.2057*t+.4673)*t-.1539)*t+.0182;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CMYKColors_poly(float t) {
  float r = ((((-4.8649*t+9.2096)*t-7.9046)*t+1.9496)*t+1.4165)*t+.2853;
  float g = (((((-40.8861*t+155.9216)*t-230.654)*t+156.3065)*t-45.0102)*t+3.7689)*t+.6424;
  float b = ((((((79.6656*t-315.6966)*t+481.3127)*t-367.3093)*t+152.3533)*t-33.5365)*t+2.4095)*t+.8792;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SouthwestColors_poly(float t) {
  float r = ((((14.5617*t-38.0584)*t+34.3532)*t-14.0528)*t+3.1836)*t+.3685;
  float g = (((5.873*t-14.1384)*t+9.8657)*t-1.3364)*t+.3333;
  float b = (((((((((3855.1752*t-19742.7225)*t+43005.4825)*t-51939.1506)*t+37939.9752)*t-17096.6302)*t+4625.0787)*t-699.2215)*t+55.0072)*t-2.3372)*t+.2202;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DeepSeaColors_poly(float t) {
  float r = ((((((((1484.4535*t-6712.0408)*t+12619.2166)*t-12762.107)*t+7492.1673)*t-2561.4098)*t+483.8659)*t-45.8569)*t+2.3549)*t+.1463;
  float g = ((-1.3995*t+2.6468)*t-.3472)*t+.0198;
  float b = ((-.2288*t-.4006)*t+1.33)*t+.2902;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 StarryNightColors_poly(float t) {
  float r = ((((5.8757*t-15.2389)*t+12.2391)*t-2.9186)*t+.9267)*t+.0804;
  float g = ((-1.387*t+1.1807)*t+.8431)*t+.1497;
  float b = (((2.0554*t-4.8787)*t+2.3401)*t+.6334)*t+.2099;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FallColors_poly(float t) {
  float r = (((-2.9878*t+4.7649)*t-1.8759)*t+.7914)*t+.2511;
  float g = (((-4.9973*t+9.9317)*t-5.2002)*t+.6679)*t+.3795;
  float b = ((-.3848*t+1.014)*t-.7716)*t+.3977;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SunsetColors_poly(float t) {
  float r = ((((((60.5337*t-222.1156)*t+313.9693)*t-208.3997)*t+61.5231)*t-6.9928)*t+2.5009)*t-.0135;
  float g = (((-2.1469*t+3.2043)*t-.9061)*t+.8346)*t-.0015;
  float b = (((((((((-1575.933*t+6907.4057)*t-12010.6555)*t+9877.5126)*t-2684.9895)*t-1738.6497)*t+1736.5118)*t-585.9981)*t+76.1077)*t-.325)*t+.0156;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FruitPunchColors_poly(float t) {
  float r = (((-3.1084*t+7.2032)*t-4.6225)*t+.4984)*t+.9888;
  float g = (((3.2033*t-4.4476)*t+.3453)*t+.7848)*t+.4941;
  float b = (((-5.6639*t+7.5443)*t-1.4725)*t+.0901)*t-.0007;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ThermometerColors_poly(float t) {
  float r = (((3.7541*t-9.0102)*t+4.8597)*t+.7785)*t+.1534;
  float g = (((5.7373*t-10.5725)*t+2.5724)*t+2.2452)*t+.0972;
  float b = ((1.6341*t-3.8711)*t+1.6136)*t+.7706;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 IslandColors_poly(float t) {
  float r = (((7.0516*t-18.0738)*t+14.4758)*t-3.5973)*t+.803;
  float g = ((.651*t-2.3608)*t+2.1193)*t+.3681;
  float b = ((((7.1244*t-18.7807)*t+19.1946)*t-11.8685)*t+4.4668)*t+.1735;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 WatermelonColors_poly(float t) {
  float r = (((-2.9967*t+4.7848)*t-2.6446)*t+1.6353)*t+.0849;
  float g = (((-1.9825*t+2.0046)*t-1.9518)*t+2.1672)*t+.0845;
  float b = (((((9.6424*t-27.1756)*t+24.2143)*t-8.874)*t+1.7496)*t+.6718)*t+.0965;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrassTones_poly(float t) {
  float r = (((((((((8254.3755*t-42237.4083)*t+91660.1592)*t-109657.3302)*t+78683.5823)*t-34519.7874)*t+9061.5885)*t-1347.7158)*t+104.1595)*t-1.6052)*t+.1594;
  float g = (((((((((7467.1378*t-38207.4039)*t+82905.7547)*t-99160.0645)*t+71113.857)*t-31163.8787)*t+8161.6983)*t-1208.668)*t+93.1469)*t-1.583)*t+.1697;
  float b = (((((((-294.0439*t+1246.9052)*t-2154.1561)*t+1939.0224)*t-961.1081)*t+251.9592)*t-30.8084)*t+2.2443)*t+.025;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenPinkTones_poly(float t) {
  float r = (((((((((-2786.4735*t+12726.1106)*t-23973.9553)*t+24017.6332)*t-13822.5137)*t+4718.1078)*t-1041.7945)*t+179.9293)*t-17.496)*t+.6787)*t-.006;
  float g = (((((((((-4390.7484*t+23124.539)*t-51437.424)*t+62740.0835)*t-45585.3544)*t+20053.9833)*t-5174.35)*t+710.4699)*t-45.749)*t+4.3777)*t+.2192;
  float b = (((((((((-4021.1895*t+18779.8371)*t-36413.2455)*t+37839.9821)*t-22723.0856)*t+7985.6114)*t-1645.1673)*t+211.7558)*t-15.0997)*t+.7993)*t+.0151;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrownCyanTones_poly(float t) {
  float r = (((1.9912*t-3.0126)*t-.9066)*t+1.9475)*t+.3309;
  float g = ((-1.0091*t-.3211)*t+1.7824)*t+.1941;
  float b = ((-1.3287*t+.2569)*t+1.7658)*t+.0681;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PigeonTones_poly(float t) {
  float r = (((-4.6787*t+8.8447)*t-4.6992)*t+1.3584)*t+.1695;
  float g = (((-3.156*t+6.4877)*t-3.9736)*t+1.4986)*t+.1483;
  float b = ((((-5.3868*t+9.5111)*t-3.7018)*t-.6554)*t+1.0081)*t+.2085;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CherryTones_poly(float t) {
  float r = (((-1.4874*t+4.9772)*t-5.9293)*t+3.2596)*t+.1844;
  float g = ((-.6178*t+2.0723)*t-.6687)*t+.2196;
  float b = ((-.7126*t+2.19)*t-.6942)*t+.2208;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RedBlueTones_poly(float t) {
  float r = (((5.2848*t-9.6961)*t+3.0966)*t+.986)*t+.4624;
  float g = ((((-5.2847*t+18.277)*t-23.1662)*t+10.2756)*t+.0291)*t+.1729;
  float b = ((-2.2853*t+1.9941)*t+.5997)*t+.2141;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CoffeeTones_poly(float t) {
  float r = ((.473*t-1.0207)*t+1.1343)*t+.4066;
  float g = (((-2.5563*t+5.866)*t-4.1417)*t+1.5245)*t+.3067;
  float b = (((((13.0069*t-41.4835)*t+46.8638)*t-19.8454)*t+1.5664)*t+.6428)*t+.2686;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RustTones_poly(float t) {
  float r = (((((-26.6965*t+79.8695)*t-86.7466)*t+40.6223)*t-8.2386)*t+2.203)*t-.0214;
  float g = (((1.7118*t-3.4326)*t+1.7217)*t+.4718)*t+.0082;
  float b = ((.0053*t+.1568)*t-.319)*t+.1963;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FuchsiaTones_poly(float t) {
  float r = ((-.468*t+.0665)*t+1.2729)*t+.0948;
  float g = (((-2.9641*t+4.8192)*t-1.8424)*t+.8082)*t+.0911;
  float b = ((-.5469*t+.3594)*t+1.0547)*t+.1014;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SiennaTones_poly(float t) {
  float r = ((.9332*t-2.3181)*t+1.8609)*t+.4396;
  float g = ((-.8034*t+.9394)*t+.5587)*t+.1755;
  float b = ((-1.3461*t+2.5043)*t-.4416)*t+.0882;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayTones_poly(float t) {
  float r = (((-2.3695*t+4.3465)*t-2.0726)*t+.916)*t+.0881;
  float g = (((-1.8715*t+3.5473)*t-1.8514)*t+1.0035)*t+.088;
  float b = (((-1.6544*t+3.3064)*t-2.0154)*t+1.156)*t+.0857;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ValentineTones_poly(float t) {
  float r = ((-.4666*t+.628)*t+.2773)*t+.5297;
  float g = ((-.7171*t+1.526)*t-.0865)*t+.1236;
  float b = ((-.7567*t+1.4386)*t-.0124)*t+.2132;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayYellowTones_poly(float t) {
  float r = ((-1.5713*t+1.7901)*t+.5203)*t+.1803;
  float g = ((-2.0787*t+2.1608)*t+.4212)*t+.2188;
  float b = (((-1.218*t-.7375)*t+1.2299)*t+.6435)*t+.294;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkTerrain_poly(float t) {
  float r = (((((-23.162*t+67.8011)*t-72.846)*t+38.6091)*t-12.5808)*t+3.2298)*t-.0316;
  float g = (((((-30.4365*t+85.6295)*t-87.1837)*t+44.12)*t-14.8493)*t+3.7107)*t+.0308;
  float b = (((((-31.1409*t+85.9958)*t-83.1945)*t+36.9212)*t-9.0114)*t+1.0112)*t+.4503;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTerrain_poly(float t) {
  float r = ((-1.3464*t+1.9755)*t-.2865)*t+.5392;
  float g = ((-1.8479*t+3.2093)*t-1.2544)*t+.7753;
  float b = ((-1.8626*t+4.125)*t-2.2288)*t+.8628;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenBrownTerrain_poly(float t) {
  float r = (((5.6637*t-9.7934)*t+4.0203)*t+1.1257)*t-.001;
  float g = (((6.0318*t-7.7796)*t+.5409)*t+2.2681)*t-.0218;
  float b = (((2.0523*t+1.2794)*t-5.021)*t+2.7336)*t-.0178;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SandyTerrain_poly(float t) {
  float r = (((((11.6277*t-25.3882)*t+19.3813)*t-7.6909)*t+.8571)*t+.8688)*t+.6525;
  float g = (((((15.2926*t-48.5603)*t+63.2318)*t-42.4573)*t+12.7141)*t-.1831)*t+.3282;
  float b = (((1.7612*t-3.2498)*t+1.3671)*t+.0933)*t+.2139;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrightBands_poly(float t) {
  float r = (((((((((8998.8583*t-49148.5979)*t+113169.766)*t-142764.1957)*t+107280.4242)*t-48843.9544)*t+13047.9439)*t-1836.6485)*t+96.2916)*t+.2077)*t+.8784;
  float g = (((((((((-6544.3325*t+27440.9056)*t-46329.6516)*t+39629.1458)*t-17242.5062)*t+2843.1945)*t+332.9976)*t-126.6414)*t-7.4364)*t+4.9893)*t+.0552;
  float b = (((((((((-17547.6824*t+76171.838)*t-135233.3159)*t+125335.9495)*t-63345.4239)*t+15640.6153)*t-520.9382)*t-618.847)*t+121.0207)*t-3.0992)*t+.255;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkBands_poly(float t) {
  float r = (((((((((20520.3381*t-97309.7443)*t+195239.1345)*t-216386.7528)*t+145275.046)*t-61042.3498)*t+16058.8484)*t-2591.3151)*t+250.8522)*t-13.9418)*t+.8142;
  float g = (((((((((13309.4153*t-56888.8281)*t+97883.5556)*t-85126.8126)*t+37253.5854)*t-5613.9766)*t-1317.2487)*t+549.3605)*t-47.6141)*t-1.4492)*t+.8927;
  float b = (((((((((13552.2468*t-77124.4239)*t+185770.9488)*t-246696.4601)*t+197022.6538)*t-96790.4391)*t+28694.9819)*t-4821.233)*t+406.6765)*t-15.7224)*t+1.0781;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Aquamarine_poly(float t) {
  float r = ((2.6585*t-3.7732)*t+1.099)*t+.6663;
  float g = ((1.6239*t-2.4244)*t+.8204)*t+.7256;
  float b = ((1.3883*t-1.781)*t+.4094)*t+.8449;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Pastel_poly(float t) {
  float r = ((((5.2009*t-13.1895)*t+10.3882)*t-3.8203)*t+1.0842)*t+.7443;
  float g = ((((11.3496*t-28.7271)*t+24.2837)*t-8.6129)*t+1.9676)*t+.4536;
  float b = ((((((81.1379*t-335.7778)*t+549.8404)*t-459.1507)*t+208.0687)*t-47.4446)*t+3.3375)*t+.8986;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BlueGreenYellow_poly(float t) {
  float r = ((.4391*t+.7429)*t-.3715)*t+.1259;
  float g = ((.4035*t-1.4246)*t+1.931)*t-.0115;
  float b = ((.7818*t-1.8058)*t+.9888)*t+.3849;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Rainbow_poly(float t) {
  float r = (((((33.1682*t-100.819)*t+116.5922)*t-68.1086)*t+23.5624)*t-4.0345)*t+.5004;
  float g = (((((39.9235*t-129.2811)*t+161.5151)*t-98.6707)*t+27.9692)*t-1.4611)*t+.1237;
  float b = (((((32.0783*t-103.1114)*t+118.4876)*t-53.2624)*t+3.2454)*t+2.1766)*t+.516;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkRainbow_poly(float t) {
  float r = ((((((-142.7682*t+504.7613)*t-673.8783)*t+417.3468)*t-119.8578)*t+15.5088)*t-.6262)*t+.2451;
  float g = (((((((-295.4882*t+1082.7516)*t-1527.3968)*t+1039.6297)*t-348.4437)*t+47.7262)*t+1.4318)*t-.2983)*t+.3454;
  float b = ((((22.3956*t-58.3336)*t+52.199)*t-17.6266)*t+1.0502)*t+.5638;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 TemperatureMap_poly(float t) {
  float r = ((((((73.3388*t-260.9259)*t+359.9373)*t-234.9464)*t+67.8889)*t-6.3532)*t+1.7211)*t+.1696;
  float g = (((((((((3485.2098*t-18023.2923)*t+39456.71)*t-47558.8722)*t+34370.0882)*t-15199.1139)*t+4025.5905)*t-602.6056)*t+45.9028)*t+.1792)*t+.3085;
  float b = (((((((((-4137.3382*t+21576.6987)*t-47304.9115)*t+56646.4862)*t-40360.5338)*t+17540.4075)*t-4608.7472)*t+701.0157)*t-55.8117)*t+1.986)*t+.9185;
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTemperatureMap_poly(float t) {
  float r = ((((((-61.3907*t+194.8151)*t-231.6686)*t+128.1464)*t-34.7571)*t+3.9043)*t+1.6238)*t+.1561;
  float g = ((.1405*t-2.9854)*t+2.93)*t+.2676;
  float b = ((((((((-1033.7746*t+4810.3542)*t-9316.0651)*t+9689.002)*t-5820.2607)*t+2024.9855)*t-392.1307)*t+38.5609)*t-1.4433)*t+.9519;
  return vec3(clp(r),clp(g),clp(b));
}

/* ====================== trigonometric series color functions ====================== */

vec3 AlpineColors_trig(float x) {
  float r = .388+.512*x+.181*cos(3.142*x+2.181);
  float g = .199+.976*x+.199*cos(3.142*x+.662);
  float b = -.512+2.345*x+.963*cos(3.142*x+.199)+.226*cos(6.283*x+1.363);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LakeColors_trig(float x) {
  float r = .247+.739*x+.063*cos(3.142*x-.917);
  float g = -.182+1.301*x+.32*cos(3.142*x-.825)+.058*cos(6.283*x+1.498);
  float b = .468+.592*x+.179*cos(3.142*x-.667)+.06*cos(6.283*x-2.996)+.021*cos(12.566*x+2.472);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ArmyColors_trig(float x) {
  float r = .947-.552*x+.451*cos(3.142*x+2.811)+.108*cos(6.283*x-2.077);
  float g = 1.304-1.217*x+.7*cos(3.142*x+2.945)+.181*cos(6.283*x-1.622);
  float b = 1.051-.861*x+.551*cos(3.142*x+2.71)+.115*cos(6.283*x-1.862);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 MintColors_trig(float x) {
  float r = .474+.436*x+.14*cos(3.142*x-1.635);
  float g = .99-.38*x+.089*cos(3.142*x-1.67);
  float b = .644+.141*x+.133*cos(3.142*x-1.611);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AtlanticColors_trig(float x) {
  float r = 1.607-2.72*x+1.547*cos(3.142*x-2.941)+.28*cos(6.283*x-1.388);
  float g = 1.575-2.507*x+1.453*cos(3.142*x-2.883)+.236*cos(6.283*x-1.572);
  float b = 1.633-2.506*x+1.51*cos(3.142*x-2.895)+.23*cos(6.283*x-1.544);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 NeonColors_trig(float x) {
  float r = .83-.148*x+.135*cos(3.142*x-2.509);
  float g = 1.636-2.115*x+.729*cos(3.142*x+2.815)+.088*cos(6.283*x-1.428)+.036*cos(12.566*x-2.08);
  float b = .532-.185*x+.339*cos(3.142*x+2.888)+.123*cos(6.283*x-.801);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AuroraColors_trig(float x) {
  float r = 1.176-.831*x+.83*cos(3.142*x+2.616)+.257*cos(6.283*x-2.45);
  float g = .036+.564*x+.317*cos(3.142*x-.493)+.248*cos(6.283*x+1.791);
  float b = .017+.711*x+.26*cos(3.142*x-1.555)+.235*cos(6.283*x+.008);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PearlColors_trig(float x) {
  float r = .111+1.453*x+.701*cos(3.142*x+.168)+.105*cos(6.283*x+.473);
  float g = .159+1.111*x+.562*cos(3.142*x-.105)+.111*cos(6.283*x+.216);
  float b = .069+1.266*x+.543*cos(3.142*x-.288)+.182*cos(6.283*x+.31);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AvocadoColors_trig(float x) {
  float r = -1.482+3.952*x+1.476*cos(3.142*x+.133)+.38*cos(6.283*x+1.559)+.028*cos(12.566*x+1.368);
  float g = -.251+1.483*x+.299*cos(3.142*x-.687);
  float b = -.106+.439*x+.098*cos(3.142*x+.065);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PlumColors_trig(float x) {
  float r = -.729+2.374*x+.71*cos(3.142*x-.046);
  float g = -.192+1.267*x+.263*cos(3.142*x+.825);
  float b = .453-.47*x+.48*cos(3.142*x-2.748);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BeachColors_trig(float x) {
  float r = .325+1.524*x+.779*cos(3.142*x+.527)+.147*cos(6.283*x+3.076);
  float g = .03+1.694*x+.623*cos(3.142*x+.36)+.116*cos(6.283*x+3.087);
  float b = .535-.062*x+.406*cos(3.142*x-2.94)+.121*cos(6.283*x-.024);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RoseColors_trig(float x) {
  float r = .299+.486*x+.117*cos(3.142*x-1.852)+.109*cos(6.283*x+3.069);
  float g = .503-.377*x+.171*cos(3.142*x-2.184)+.089*cos(6.283*x+3.038);
  float b = .165-.021*x+.174*cos(3.142*x-1.691)+.054*cos(6.283*x+3.058);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CandyColors_trig(float x) {
  float r = .774-.379*x+.371*cos(3.142*x-2.605)+.154*cos(6.283*x-1.902);
  float g = .605-.004*x+.36*cos(3.142*x+2.765)+.052*cos(6.283*x-3.058);
  float b = .8-.375*x+.452*cos(3.142*x-3.047);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SolarColors_trig(float x) {
  float r = .257+.951*x+.306*cos(3.142*x-.869);
  float g = .266+.288*x+.26*cos(3.142*x+3.012);
  float b = .062+.016*x+.06*cos(3.142*x+2.445);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CMYKColors_trig(float x) {
  float r = 1.548-3.031*x+1.765*cos(3.142*x-2.507)+.221*cos(6.283*x-.724);
  float g = -1.734+3.258*x+2.223*cos(3.142*x-.534)+.851*cos(6.283*x+1.026)+.05*cos(12.566*x+.109);
  float b = 1.389-2.952*x+1.531*cos(3.142*x-2.345)+.546*cos(6.283*x-.206)+.056*cos(12.566*x+.462);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SouthwestColors_trig(float x) {
  float r = -1.089+2.726*x+1.514*cos(3.142*x-.434)+.337*cos(6.283*x+1.286);
  float g = .992-.784*x+.529*cos(3.142*x+3.123)+.144*cos(6.283*x+3.137);
  float b = -.355+2.292*x+1.067*cos(3.142*x+.711)+.312*cos(6.283*x+2.973)+.046*cos(12.566*x+.005)+.016*cos(18.85*x+.014)+.007*cos(25.133*x+2.161);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DeepSeaColors_trig(float x) {
  float r = -.865+2.54*x+.968*cos(3.142*x+.133)+.081*cos(6.283*x+1.016)+.025*cos(12.566*x+1.009)+.021*cos(18.85*x+1.301);
  float g = .323+.28*x+.339*cos(3.142*x+2.74);
  float b = .35+.599*x+.187*cos(3.142*x-1.847);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 StarryNightColors_trig(float x) {
  float r = -.092+1.192*x+.18*cos(3.142*x-.53)+.115*cos(6.283*x+1.394);
  float g = .469+.021*x+.379*cos(3.142*x-2.529);
  float b = .368-.19*x+.393*cos(3.142*x-2.022);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FallColors_trig(float x) {
  float r = .404+.222*x+.286*cos(3.142*x-2.557)+.088*cos(6.283*x+.067);
  float g = .272+.386*x+.009*cos(3.142*x+2.949)+.123*cos(6.283*x+.009);
  float b = .477-.312*x+.136*cos(3.142*x+2.254);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SunsetColors_trig(float x) {
  float r = 1.002-.806*x+.937*cos(3.142*x-2.848)+.246*cos(6.283*x-1.979);
  float g = -.166+1.201*x+.124*cos(3.142*x-.699)+.089*cos(6.283*x+.827);
  float b = 7.061-13.028*x+7.02*cos(3.142*x+3.092)+1.788*cos(6.283*x-1.526)+.194*cos(12.566*x-1.916)+.049*cos(18.85*x-2.292)+.015*cos(25.133*x-2.897);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FruitPunchColors_trig(float x) {
  float r = .666+.482*x+.261*cos(3.142*x+.185)+.072*cos(6.283*x+.1);
  float g = .087+.841*x+.481*cos(3.142*x-.074)+.076*cos(6.283*x+3.028);
  float b = .743-1.307*x+.97*cos(3.142*x-2.782)+.17*cos(6.283*x-.077);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ThermometerColors_trig(float x) {
  float r = 1.011-1.233*x+.9*cos(3.142*x-2.659)+.105*cos(6.283*x-2.117);
  float g = .121+.077*x+.664*cos(3.142*x-1.49)+.084*cos(6.283*x-2.796);
  float b = .428+.096*x+.501*cos(3.142*x-.759);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 IslandColors_trig(float x) {
  float r = 2.031-2.229*x+1.09*cos(3.142*x+2.856)+.201*cos(6.283*x-2.984);
  float g = -.421+1.871*x+.847*cos(3.142*x-.565)+.123*cos(6.283*x+1.123);
  float b = -1.173+2.65*x+1.509*cos(3.142*x-.584)+.207*cos(6.283*x+1.087);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 WatermelonColors_trig(float x) {
  float r = .245+.256*x+.467*cos(3.142*x-2.172)+.108*cos(6.283*x+.008);
  float g = .418-.663*x+.956*cos(3.142*x-2.066)+.123*cos(6.283*x-.028);
  float b = .814-1.542*x+1.128*cos(3.142*x-2.473)+.167*cos(6.283*x-.048);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrassTones_trig(float x) {
  float r = .978-1.276*x+.796*cos(3.142*x-2.527)+.183*cos(6.283*x-2.455)+.043*cos(12.566*x+2.614)+.018*cos(18.85*x-.696)+.017*cos(25.133*x-3.093);
  float g = .83-1.005*x+.637*cos(3.142*x-2.484)+.156*cos(6.283*x-2.603)+.04*cos(12.566*x+2.521)+.017*cos(18.85*x-.656)+.015*cos(25.133*x-3.096);
  float b = .28-.554*x+.504*cos(3.142*x-2.152)+.043*cos(6.283*x-1.134)+.012*cos(12.566*x+1.422)+.015*cos(18.85*x-.354);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenPinkTones_trig(float x) {
  float r = -2.248+5.087*x+2.457*cos(3.142*x-.168)+.833*cos(6.283*x+1.801)+.085*cos(12.566*x+1.321)+.01*cos(18.85*x-2.587);
  float g = 1.323-2.151*x+1.112*cos(3.142*x-2.654)+.483*cos(6.283*x-1.783)+.032*cos(12.566*x-1.064)+.024*cos(18.85*x+2.64);
  float b = -1.316+3.182*x+1.554*cos(3.142*x-.302)+.619*cos(6.283*x+1.822)+.056*cos(12.566*x+1.205)+.019*cos(18.85*x-2.531);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrownCyanTones_trig(float x) {
  float r = .112+.45*x+.534*cos(3.142*x-1.153);
  float g = .491-.278*x+.691*cos(3.142*x-2.124)+.07*cos(6.283*x-.394);
  float b = .601-.427*x+.746*cos(3.142*x-2.41)+.061*cos(6.283*x-.967);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PigeonTones_trig(float x) {
  float r = .72-.517*x+.673*cos(3.142*x-2.916)+.166*cos(6.283*x-.687);
  float g = .568-.146*x+.497*cos(3.142*x-2.923)+.134*cos(6.283*x-.864);
  float b = .655-.321*x+.563*cos(3.142*x-2.921)+.163*cos(6.283*x-.847);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CherryTones_trig(float x) {
  float r = -.408+1.868*x+.664*cos(3.142*x-.658)+.074*cos(6.283*x+.212);
  float g = .341+.514*x+.309*cos(3.142*x+2.032);
  float b = .363+.469*x+.314*cos(3.142*x+2.1);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RedBlueTones_trig(float x) {
  float r = -.186+1.151*x+.811*cos(3.142*x-.463)+.142*cos(6.283*x+2.33);
  float g = 1.249-1.858*x+1.086*cos(3.142*x-2.732)+.163*cos(6.283*x-2.135);
  float b = .737-.701*x+.616*cos(3.142*x-2.543);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CoffeeTones_trig(float x) {
  float r = .277+.715*x+.196*cos(3.142*x-1.224)+.05*cos(6.283*x-.153);
  float g = .118+.933*x+.154*cos(3.142*x-.647)+.073*cos(6.283*x-.119);
  float b = -.123+1.359*x+.333*cos(3.142*x+.43)+.083*cos(6.283*x-.343);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RustTones_trig(float x) {
  float r = .018+.905*x+.269*cos(3.142*x-1.772)+.011*cos(6.283*x-1.846)+.022*cos(12.566*x-.025);
  float g = .058+.452*x+.03*cos(3.142*x-1.911)+.041*cos(6.283*x-3.104);
  float b = .193-.155*x+.04*cos(3.142*x+1.542);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FuchsiaTones_trig(float x) {
  float r = .206+.665*x+.186*cos(3.142*x-2.168);
  float g = .152+.539*x+.184*cos(3.142*x-2.488)+.086*cos(6.283*x+.228);
  float b = .228+.626*x+.165*cos(3.142*x-2.404);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SiennaTones_trig(float x) {
  float r = .245+.889*x+.305*cos(3.142*x-.818);
  float g = .357+.339*x+.191*cos(3.142*x-2.797);
  float b = .38+.12*x+.323*cos(3.142*x+2.769);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayTones_trig(float x) {
  float r = .074+.728*x+.067*cos(3.142*x-2.376)+.064*cos(6.283*x+.119);
  float g = .061+.784*x+.055*cos(3.142*x-2.002)+.051*cos(6.283*x+.078);
  float b = .025+.821*x+.082*cos(3.142*x-1.403)+.049*cos(6.283*x+.057);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ValentineTones_trig(float x) {
  float r = .634+.233*x+.105*cos(3.142*x-2.985);
  float g = .277+.406*x+.194*cos(3.142*x+2.54);
  float b = .377+.335*x+.184*cos(3.142*x+2.726);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayYellowTones_trig(float x) {
  float r = .534+.045*x+.376*cos(3.142*x-2.768);
  float g = .689-.413*x+.517*cos(3.142*x-2.678);
  float b = .997-1.658*x+1.04*cos(3.142*x-2.436)+.091*cos(6.283*x-.185);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkTerrain_trig(float x) {
  float r = -.096+1.159*x+.07*cos(3.142*x+.46)+.173*cos(6.283*x-1.572)+.024*cos(12.566*x-.787);
  float g = -.016+1.058*x+.103*cos(3.142*x+1.144)+.269*cos(6.283*x-1.574)+.031*cos(12.566*x-.719);
  float b = 1.314-.929*x+.996*cos(3.142*x+2.413)+.42*cos(6.283*x-1.854)+.033*cos(12.566*x-1.018);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTerrain_trig(float x) {
  float r = .836-.25*x+.299*cos(3.142*x-3.102);
  float g = 1.177-.708*x+.424*cos(3.142*x+2.892);
  float b = 1.373-.879*x+.631*cos(3.142*x+2.385)+.05*cos(6.283*x-2.97);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenBrownTerrain_trig(float x) {
  float r = -.456+2.198*x+.593*cos(3.142*x+.15)+.153*cos(6.283*x+2.825);
  float g = -.72+2.757*x+.875*cos(3.142*x+.189)+.162*cos(6.283*x-3.03);
  float b = -1.619+4.383*x+1.686*cos(3.142*x+.155)+.116*cos(6.283*x+2.243);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SandyTerrain_trig(float x) {
  float r = .856-.492*x+.237*cos(3.142*x-1.829)+.115*cos(6.283*x+3.084)+.026*cos(12.566*x-2.294);
  float g = .956-.856*x+.46*cos(3.142*x-2.901)+.187*cos(6.283*x-2.624)+.022*cos(12.566*x-3.008);
  float b = -.238+.949*x+.478*cos(3.142*x-.063)+.09*cos(6.283*x+2.03);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrightBands_trig(float x) {
  float r = -15.094+28.349*x+14.303*cos(3.142*x-.183)+3.387*cos(6.283*x+1.15)+.301*cos(12.566*x+.968)+.118*cos(18.85*x+.097)+.084*cos(25.133*x+.329);
  float g = 31.195-61.605*x+31.094*cos(3.142*x-3.125)+6.593*cos(6.283*x-1.576)+.723*cos(12.566*x-1.552)+.246*cos(18.85*x-1.496)+.111*cos(25.133*x-1.355);
  float b = -5.6+14.722*x+7.402*cos(3.142*x+.254)+1.395*cos(6.283*x+2.297)+.335*cos(12.566*x+2.606)+.09*cos(18.85*x-2.44)+.075*cos(25.133*x+1.97);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkBands_trig(float x) {
  float r = -25.372+53.463*x+26.644*cos(3.142*x+.041)+5.688*cos(6.283*x+1.658)+.614*cos(12.566*x+1.508)+.243*cos(18.85*x+1.638)+.143*cos(25.133*x+2.06);
  float g = -15.718+32.09*x+16.082*cos(3.142*x-.029)+3.459*cos(6.283*x+1.462)+.349*cos(12.566*x+1.378)+.214*cos(18.85*x+1.376)+.062*cos(25.133*x+1.487);
  float b = 17.533-34.788*x+17.058*cos(3.142*x-3.103)+3.391*cos(6.283*x-1.454)+.303*cos(12.566*x-1.417)+.182*cos(18.85*x-1.31)+.016*cos(25.133*x-1.29);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Aquamarine_trig(float x) {
  float r = .078+1.156*x+.593*cos(3.142*x+.088);
  float g = .368+.735*x+.361*cos(3.142*x+.008);
  float b = .535+.628*x+.317*cos(3.142*x+.232);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Pastel_trig(float x) {
  float r = .52+.009*x+.523*cos(3.142*x-1.23)+.113*cos(6.283*x+1.097);
  float g = -.471+2.033*x+.965*cos(3.142*x-.398)+.247*cos(6.283*x+1.404);
  float b = -1.284+3.613*x+1.841*cos(3.142*x-.199)+.54*cos(6.283*x+.874)+.067*cos(12.566*x+.6);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BlueGreenYellow_trig(float x) {
  float r = .011+1.004*x+.353*cos(3.142*x+1.29);
  float g = -.091+1.088*x+.218*cos(3.142*x-1.145);
  float b = .221+.31*x+.232*cos(3.142*x-.722);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Rainbow_trig(float x) {
  float r = 2.01-2.371*x+1.427*cos(3.142*x+2.85)+.147*cos(6.283*x-2.611)+.03*cos(12.566*x+3.114);
  float g = 2.007-3.531*x+1.814*cos(3.142*x-2.908)+.29*cos(6.283*x-1.923)+.034*cos(12.566*x-3.051);
  float b = -.15+.385*x+.767*cos(3.142*x-1.048)+.281*cos(6.283*x-.393);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkRainbow_trig(float x) {
  float r = -.032+1.237*x+.371*cos(3.142*x+.131)+.256*cos(6.283*x+1.942)+.046*cos(12.566*x-1.755);
  float g = .258+1.012*x+.689*cos(3.142*x+.645)+.441*cos(6.283*x+2.625)+.082*cos(12.566*x-2.507)+.009*cos(18.85*x-2.116);
  float b = -1.472+3.662*x+1.998*cos(3.142*x+.024)+.488*cos(6.283*x+1.466);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 TemperatureMap_trig(float x) {
  float r = 1.23-1.227*x+.958*cos(3.142*x-2.875)+.227*cos(6.283*x-2.127);
  float g = 2.512-4.882*x+2.553*cos(3.142*x-2.731)+.391*cos(6.283*x-1.308)+.035*cos(12.566*x-1.27)+.021*cos(18.85*x-.69);
  float b = -1.384+4.044*x+2.401*cos(3.142*x-.028)+.387*cos(6.283*x+1.914)+.09*cos(12.566*x+.862)+.028*cos(18.85*x+2.287);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTemperatureMap_trig(float x) {
  float r = 1.034-1.062*x+.955*cos(3.142*x-2.715)+.165*cos(6.283*x-1.705)+.031*cos(12.566*x-1.065);
  float g = .056+.33*x+.875*cos(3.142*x-1.433)+.089*cos(6.283*x+.194);
  float b = -.49+2.209*x+1.485*cos(3.142*x-.14)+.271*cos(6.283*x+1.846)+.039*cos(12.566*x+1.116);
  return vec3(clp(r),clp(g),clp(b));
}

/* ====================== cosine color plaettes ====================== */

vec3 AlpineColors_cosine(float t) {
  float r = .34+.562*t+.15*cos(3.468*t+1.969);
  float g = .257+.75*t+.093*cos(4.562*t+.16);
  float b = .431+.302*t+.173*cos(4.864*t+1.108);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LakeColors_cosine(float t) {
  float r = .254+.731*t+.058*cos(3.275*t-1.005);
  float g = .132+.669*t+.25*cos(3.073*t-1.904);
  float b = .338+.725*t+.297*cos(3.358*t-.976);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ArmyColors_cosine(float t) {
  float r = .345+.527*t+.109*cos(2.623*t+.641);
  float g = .427+.427*t+.144*cos(4.132*t+.063);
  float b = .386+.174*t+.066*cos(6.358*t-.264);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 MintColors_cosine(float t) {
  float r = -.619+.176*t+1.394*cos(.93*t-.688);
  float g = .426-.597*t+.798*cos(.992*t-.81);
  float b = .264+.088*t+.541*cos(1.457*t-.817);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AtlanticColors_cosine(float t) {
  float r = .118-.518*t+.909*cos(1.609*t-1.577);
  float g = .309-.072*t+.477*cos(2.921*t-1.956);
  float b = .464-.507*t+.749*cos(2.484*t-2.026);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 NeonColors_cosine(float t) {
  float r = .772+.066*t+.044*cos(5.935*t-3.554);
  float g = .832-.792*t+.139*cos(5.937*t+.756);
  float b = .142+.513*t+.133*cos(5.692*t+.064);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AuroraColors_cosine(float t) {
  float r = .209+.586*t+.05*cos(10.516*t-4.856);
  float g = .511-.234*t+.282*cos(5.461*t+2.466);
  float b = .167+.704*t+.122*cos(7.581*t-.642);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PearlColors_cosine(float t) {
  float r = .721+.133*t+.197*cos(5.404*t-.179);
  float g = .784-.07*t+.112*cos(6.567*t-.891);
  float b = .713+.151*t+.11*cos(7.189*t-.772);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 AvocadoColors_cosine(float t) {
  float r = .655-.2*t+.649*cos(2.755*t+2.923);
  float g = -.678+2.051*t+.657*cos(2.279*t-.098);
  float b = -.013+.246*t+.022*cos(5.897*t-1.248);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PlumColors_cosine(float t) {
  float r = -1.019+2.938*t+1.008*cos(2.766*t+.148);
  float g = -.129+.886*t+.084*cos(6.614*t-.542);
  float b = 2.035-4.714*t+3.865*cos(1.482*t+4.159);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BeachColors_cosine(float t) {
  float r = -.179+2.163*t+1.031*cos(2.623*t+.345);
  float g = .559+.364*t+.081*cos(7.607*t-2.555);
  float b = .149+.801*t+.105*cos(6.822*t+.376);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RoseColors_cosine(float t) {
  float r = .324+.541*t+.17*cos(5.629*t-2.919);
  float g = .482-.211*t+.17*cos(5.382*t-2.917);
  float b = .221+.002*t+.159*cos(4.866*t-2.524);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CandyColors_cosine(float t) {
  float r = .43+.468*t+.213*cos(4.928*t-1.749);
  float g = .106+.828*t+.031*cos(11.046*t-.4);
  float b = .483+.298*t+.165*cos(4.659*t+2.531);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SolarColors_cosine(float t) {
  float r = -.325+1.625*t+.778*cos(2.093*t-.134);
  float g = .027+.73*t+.077*cos(5.134*t+1.925);
  float b = .172-.13*t+.155*cos(2.134*t+3.136);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CMYKColors_cosine(float t) {
  float r = .61+.194*t+.081*cos(10.715*t+.114);
  float g = .963-.695*t+.363*cos(6.258*t+1.694);
  float b = .857-.536*t+.098*cos(9.08*t-1.018);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SouthwestColors_cosine(float t) {
  float r = .848-2.173*t+1.659*cos(1.874*t-1.808);
  float g = .441+.304*t+.174*cos(6.236*t+2.533);
  float b = -.269+1.247*t+.315*cos(3.882*t-.317);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DeepSeaColors_cosine(float t) {
  float r = -.452+1.772*t+.586*cos(3.484*t+.168);
  float g = .395+.166*t+.399*cos(2.951*t+2.859);
  float b = .209+.358*t+.487*cos(1.901*t-1.398);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 StarryNightColors_cosine(float t) {
  float r = .188+.741*t+.121*cos(5.253*t+2.268);
  float g = .494-.068*t+.427*cos(2.988*t+3.806);
  float b = .391-.019*t+.267*cos(3.939*t-2.331);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FallColors_cosine(float t) {
  float r = .207+.806*t+.041*cos(8.621*t-.258);
  float g = .262+.403*t+.124*cos(6.28*t+.023);
  float b = .307-.118*t+.041*cos(7.41*t-.251);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SunsetColors_cosine(float t) {
  float r = .138+1.15*t+.267*cos(5.058*t-2.215);
  float g = -.054+1.068*t+.043*cos(7.883*t+.103);
  float b = -.065+.734*t+.322*cos(7.069*t-1.202);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FruitPunchColors_cosine(float t) {
  float r = .895-.02*t+.109*cos(5.773*t-.213);
  float g = .569-.095*t+.137*cos(5.769*t-2.086);
  float b = -.038+.685*t+.136*cos(6.99*t+1.023);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ThermometerColors_cosine(float t) {
  float r = .453+.122*t+.385*cos(4.177*t-2.507);
  float g = .284+.142*t+.554*cos(4.181*t-1.918);
  float b = .464+.05*t+.475*cos(3.217*t-.809);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 IslandColors_cosine(float t) {
  float r = .67+.125*t+.142*cos(7.543*t+1.454);
  float g = -.363+1.194*t+.825*cos(2.085*t-.458);
  float b = -.248+.869*t+.821*cos(2.872*t-.925);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 WatermelonColors_cosine(float t) {
  float r = .171+.9*t+.038*cos(13.945*t-3.805);
  float g = .749-2.337*t+1.967*cos(2.013*t-1.894);
  float b = .161+.66*t+.085*cos(10.552*t-.376);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrassTones_cosine(float t) {
  float r = .16+.07*t+.727*cos(3.313*t-1.671);
  float g = .238+.004*t+.595*cos(3.492*t-1.798);
  float b = .118-.036*t+.312*cos(3.548*t-1.885);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenPinkTones_cosine(float t) {
  float r = .529-.054*t+.55*cos(5.498*t+2.779);
  float g = .21+.512*t+.622*cos(4.817*t-1.552);
  float b = .602-.212*t+.569*cos(5.266*t+2.861);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrownCyanTones_cosine(float t) {
  float r = .203+.373*t+.472*cos(3.367*t-1.293);
  float g = .307-1.235*t+1.606*cos(1.806*t-1.637);
  float b = .587-3.096*t+3.441*cos(1.409*t-1.721);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 PigeonTones_cosine(float t) {
  float r = .115+.864*t+.065*cos(7.663*t-.48);
  float g = .134+.845*t+.042*cos(7.904*t-.989);
  float b = .166+.795*t+.057*cos(7.722*t-.96);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CherryTones_cosine(float t) {
  float r = -.507+2.128*t+.743*cos(2.704*t-.219);
  float g = -.011+.83*t+.103*cos(7.685*t-.517);
  float b = -.01+.837*t+.101*cos(7.825*t-.558);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RedBlueTones_cosine(float t) {
  float r = .649-.248*t+.33*cos(4.743*t-2.171);
  float g = .46+.013*t+.388*cos(4.495*t-2.538);
  float b = .912-1.304*t+.961*cos(2.624*t+3.913);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 CoffeeTones_cosine(float t) {
  float r = -.275+1.604*t+.75*cos(1.609*t+.425);
  float g = .32+.635*t+.04*cos(7.862*t-1.389);
  float b = .064+.864*t+.199*cos(5.276*t-.159);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 RustTones_cosine(float t) {
  float r = .122+1.015*t+.12*cos(5.857*t-2.927);
  float g = .062+.473*t+.056*cos(5.844*t-2.93);
  float b = .17-.157*t+.019*cos(5.848*t+.205);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 FuchsiaTones_cosine(float t) {
  float r = .271-.695*t+1.499*cos(1.307*t-1.688);
  float g = .034+.905*t+.05*cos(7.864*t-.057);
  float b = .615-1.141*t+1.82*cos(1.25*t-1.857);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SiennaTones_cosine(float t) {
  float r = -.412+1.682*t+.857*cos(2.03*t-.038);
  float g = .327+.416*t+.153*cos(3.422*t+3.376);
  float b = .397+.093*t+.337*cos(3.09*t+2.801);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayTones_cosine(float t) {
  float r = .043+.841*t+.044*cos(7.064*t-.075);
  float g = .061+.84*t+.03*cos(7.431*t-.36);
  float b = .088+.793*t+.017*cos(9.001*t-1.351);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 ValentineTones_cosine(float t) {
  float r = .515+.491*t+.012*cos(9.911*t-.531);
  float g = .135+.605*t+.1*cos(4.255*t+1.819);
  float b = .173+.657*t+.053*cos(5.679*t+1.147);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GrayYellowTones_cosine(float t) {
  float r = .6-.129*t+.468*cos(2.889*t+3.612);
  float g = .257+.751*t+.049*cos(10.88*t-.313);
  float b = .458+.293*t+.082*cos(10.715*t-.059);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkTerrain_cosine(float t) {
  float r = -.411+1.77*t+.425*cos(4.184*t-.465);
  float g = -5.313+12.05*t+7.18*cos(1.752*t+.736);
  float b = -.034+1.018*t+.43*cos(5.044*t-.453);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTerrain_cosine(float t) {
  float r = .585+.263*t+.087*cos(5.119*t+2.234);
  float g = .608+.282*t+.058*cos(8.688*t-.184);
  float b = .55+.174*t+.129*cos(7.825*t-.327);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 GreenBrownTerrain_cosine(float t) {
  float r = .117+.953*t+.119*cos(6.758*t-2.887);
  float g = .12+.881*t+.181*cos(6.804*t-2.345);
  float b = -.34+1.52*t+.402*cos(4.822*t-.711);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 SandyTerrain_cosine(float t) {
  float r = .903-.539*t+.319*cos(4.28*t-2.369);
  float g = .481+.071*t+.271*cos(4.704*t-2.322);
  float b = .264-.027*t+.058*cos(5.68*t-2.617);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BrightBands_cosine(float t) {
  float r = .631+.13*t+.314*cos(7.388*t-.03);
  float g = .52+.312*t+.288*cos(5.462*t-3.023);
  float b = -.129+1.322*t+.767*cos(4.932*t-1.138);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkBands_cosine(float t) {
  float r = .516+.307*t+.147*cos(11.59*t-5.506);
  float g = .621+.214*t+.262*cos(4.299*t+.764);
  float b = 1.077-.984*t+.355*cos(5.115*t+1.765);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Aquamarine_cosine(float t) {
  float r = -.304+1.962*t+1.037*cos(2.567*t+.358);
  float g = .262+.949*t+.472*cos(2.849*t+.153);
  float b = -.204+2.356*t+1.507*cos(1.8*t+.802);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Pastel_cosine(float t) {
  float r = .94-.191*t+.054*cos(10.715*t+.139);
  float g = 1.695-3.634*t+2.889*cos(1.558*t+4.289);
  float b = .813-.068*t+.215*cos(5.582*t+.594);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 BlueGreenYellow_cosine(float t) {
  float r = 2.081+4.672*t+6.442*cos(.818*t+1.879);
  float g = -.467+1.408*t+.504*cos(2.071*t-.424);
  float b = -1.062+1.975*t+1.607*cos(1.481*t+.447);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 Rainbow_cosine(float t) {
  float r = .132+.851*t+.109*cos(9.597*t-.378);
  float g = .385-1.397*t+1.319*cos(2.391*t-1.839);
  float b = .116+.645*t+.54*cos(3.882*t-.475);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 DarkRainbow_cosine(float t) {
  float r = .25+.638*t+.163*cos(7.885*t+1.194);
  float g = .655-.343*t+.28*cos(5.831*t+2.688);
  float b = .523-.4*t+.113*cos(6.931*t+.596);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 TemperatureMap_cosine(float t) {
  float r = .372+.707*t+.265*cos(5.201*t-2.515);
  float g = .888-2.123*t+1.556*cos(2.483*t+4.324);
  float b = 1.182-.943*t+.195*cos(8.032*t-3.409);
  return vec3(clp(r),clp(g),clp(b));
}
vec3 LightTemperatureMap_cosine(float t) {
  float r = .385+.619*t+.238*cos(4.903*t-2.61);
  float g = -.108+.2*t+1.021*cos(2.463*t-1.172);
  float b = 1.107-.734*t+.172*cos(6.07*t-2.741);
  return vec3(clp(r),clp(g),clp(b));
}

/* ====================== main ====================== */

void main(void) {
    vec2 uv = (vec2(0,1)-(gl_FragCoord.xy/resolution.xy))*vec2(-4, 13);
    int i = int(uv.x)*13+int(uv.y);
    float t = fract(uv.x);
    vec3 col = vec3(0);
    if (i==0) col=AlpineColors_trig(t);
    if (i==1) col=LakeColors_trig(t);
    if (i==2) col=ArmyColors_trig(t);
    if (i==3) col=MintColors_trig(t);
    if (i==4) col=AtlanticColors_trig(t);
    if (i==5) col=NeonColors_trig(t);
    if (i==6) col=AuroraColors_trig(t);
    if (i==7) col=PearlColors_trig(t);
    if (i==8) col=AvocadoColors_trig(t);
    if (i==9) col=PlumColors_trig(t);
    if (i==10) col=BeachColors_trig(t);
    if (i==11) col=RoseColors_trig(t);
    if (i==12) col=CandyColors_trig(t);
    if (i==13) col=SolarColors_trig(t);
    if (i==14) col=CMYKColors_trig(t);
    if (i==15) col=SouthwestColors_trig(t);
    if (i==16) col=DeepSeaColors_trig(t);
    if (i==17) col=StarryNightColors_trig(t);
    if (i==18) col=FallColors_trig(t);
    if (i==19) col=SunsetColors_trig(t);
    if (i==20) col=FruitPunchColors_trig(t);
    if (i==21) col=ThermometerColors_trig(t);
    if (i==22) col=IslandColors_trig(t);
    if (i==23) col=WatermelonColors_trig(t);
    if (i==24) col=BrassTones_trig(t);
    if (i==25) col=GreenPinkTones_trig(t);
    if (i==26) col=BrownCyanTones_trig(t);
    if (i==27) col=PigeonTones_trig(t);
    if (i==28) col=CherryTones_trig(t);
    if (i==29) col=RedBlueTones_trig(t);
    if (i==30) col=CoffeeTones_trig(t);
    if (i==31) col=RustTones_trig(t);
    if (i==32) col=FuchsiaTones_trig(t);
    if (i==33) col=SiennaTones_trig(t);
    if (i==34) col=GrayTones_trig(t);
    if (i==35) col=ValentineTones_trig(t);
    if (i==36) col=GrayYellowTones_trig(t);
    if (i==37) col=DarkTerrain_trig(t);
    if (i==38) col=LightTerrain_trig(t);
    if (i==39) col=GreenBrownTerrain_trig(t);
    if (i==40) col=SandyTerrain_trig(t);
    if (i==41) col=BrightBands_trig(t);
    if (i==42) col=DarkBands_trig(t);
    if (i==43) col=Aquamarine_trig(t);
    if (i==44) col=Pastel_trig(t);
    if (i==45) col=BlueGreenYellow_trig(t);
    if (i==46) col=Rainbow_trig(t);
    if (i==47) col=DarkRainbow_trig(t);
    if (i==48) col=TemperatureMap_trig(t);
    if (i==49) col=LightTemperatureMap_trig(t);
    glFragColor = vec4(col, 0);
}
