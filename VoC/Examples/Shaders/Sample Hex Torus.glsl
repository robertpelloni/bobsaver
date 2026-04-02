#version 420

// original https://www.shadertoy.com/view/wlG3Wy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

# define time time
# define PI 3.141592654
# define MaxSteps 200. // max steps for ray marching

vec3 torus1Pos() {return vec3(0.,0.,0.);}
vec2 torus1Size() {return vec2(45.3,17.5);}

//float tRadSpeed = time;
float torusRotSpeed() {return time;}
float inOut = -1.; // -1 inside torus, 1 outside torus

vec3 spherePos() {return vec3(0, 2.5, 40.);}

vec3 camerapos() {return vec3(0., 2.5, 60.);}
vec3 cameralookat() {return vec3(15.*cos(time),15.*sin(time),0.);}
vec3 LightPos()
//{   
//    float a = 40.;   
//    return vec3(sin(time)*a,2.5,cos(time)*a);
//}
{return camerapos()+vec3(0.,0.,-0.);} //vec3(35*sin(time), 15, 35*cos(time)); //vec3(0,1.7 + 1.3*sin(0.3*q26),0); //vec3(sin(q26*4 + time*0.5)*8, 10 + 4*sin(time),cos(q26*2.5 + time*0.3)*8); //camerapos + 0*vec3(sin(time)*5,4,cos(time)*5) + 0*vec3(0,4.5 + 0*2.4*sin(time*0.3),0);

vec3 RotX (vec3 p, float speed)
{
    return vec3(p.x, p.y*cos(speed) + p.z*-sin(speed),  p.y*sin(speed) + p.z*cos(speed));
}
vec3 RotY (vec3 p, float speed)
{
    return vec3(p.x*cos(speed) + p.z*sin(speed), p.y, p.x*-sin(speed) + p.z*cos(speed));
}
vec3 RotZ (vec3 p, float speed)
{
    return vec3(p.x*cos(speed)  + p.y*-sin(speed), p.x*sin(speed) + p.y*cos(speed), p.z);
}
vec3 lum(vec3 col)
{
    float gray = 0.2989 * col.x + 0.5870 * col.y + 0.1140 * col.z;
    return vec3(gray);
}
vec3 GetTorus1Pos()
{
    vec3 pos = torus1Pos();
    //pos = RotY(torus1Pos, time*2.);
    return pos;
}
float smin( float a, float b, float k )
{
    float h = clamp(0.5 + 0.5*(b-a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1.-h);
}
// Hexagon Dist by BigWings
float HexDist(vec2 p) {
    p = abs(p);
    
    float c = dot(p, normalize(vec2(1.,1.73)));
    c = max(c, p.x);
    
    return c;
}
// Hash function by BigWings
vec2 N22(vec2 p)
{
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}
// Hexagon Coords by BigWings
vec4 HexCoords(vec2 UV) 
{
        vec2 r = vec2(1., 1.73);
    vec2 h = r*.5;
    
    vec2 a = mod(UV, r)-h;
    vec2 b = mod(UV-h, r)-h;
    
    vec2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    float x = atan(gv.x, gv.y);
    float y = .5-HexDist(gv);
    vec2 id = UV - gv;
    return vec4(x, y, id.x,id.y);
}
vec3 Hive(vec2 UV)
{
    vec3 col = vec3(0);
    vec4 hc = HexCoords(UV);
    float c = smoothstep(0.08, 0.11, hc.y); // inside each hexagon (without the edges)
    
    // waves based on hexagon's ID
    float b1 = 0.5 + 0.43*sin(hc.z*5. + hc.w*3. + 4.*time);
    // Spirals on each hexagon
    float b2 = 0.5 + 0.5*cos(hc.x*10. + hc.y*45. + 8.*time);
    
/*    vec4 ehc = HexCoords((hc.xz+0.1*vec2(0., time))*3.*vec2(2.0693,2.5) + 100. + vec2(4.,0.));
    float hexagons = smoothstep(0.,0.01, ehc.y)*mod(ehc.z,2.)*mod(ehc.w,2.);
    float b3 = b1*(1.-hexagons);

    
    float everyOtherTile = mod(hc.z,2.);//hc.z%2.;
    if( everyOtherTile == 0. ) {
        everyOtherTile = 0.; }
    else if( everyOtherTile == 1. ) {
        everyOtherTile = 1.; }
    else {everyOtherTile = 0.5;}
*/ 
    float edges = 1.-c;
    float eSquares = cos(hc.y*20. + time)*sin(hc.x*20. + time); // edges squares
    eSquares = smoothstep(0.,0.01,eSquares);
    float b4 = edges * eSquares; 

    col = b2*(1.-b1)*c*vec3(0.4274,0.847,0.8941) // azur color for the inverse of the waves
          + b1*c*vec3(0.4078,0.1725,0.0705)  // brown color for the waves
          + vec3(b1,0,(1.-b1))*c*0.3          // add some rg colors to the waves and to the inverse of them
          + b4*vec3(0.8431,0.7607,0.5019);   // brown-ish color for the edges of each hexagon

    //vec3 test = vec3(hc.zw*0.005,0.);//everyOtherTile;
    
    vec3 woodTex = vec3(0.0); //texture(iChannel0, UV*0.2).xyz;
    return (woodTex*col+0.7*col);
}
vec2 GetTorusUV(vec3 p, vec2 torusSize)
{
    float x = atan(p.x, p.z);
    float y = atan(length(p.xz)-torusSize.x, p.y);
    return vec2(x,y);    
}
float sdTorus1(vec3 p, vec2 r, float a) {
    float torusDist = length( vec2(length(p.xz) - r.x, p.y) ) - r.y; 
    
    vec2 tUV = GetTorusUV(p, torus1Size());   
    vec4 h = HexCoords(tUV*vec2(6.,3.03) + 1000. + torusRotSpeed());
    float hive = 0.25*smoothstep(0.,0.1,h.y) - 0.4*smoothstep(0.1,0.2,h.y);
    float hexTorus = torusDist + hive;

    float holesTorus = max(-hexTorus,torusDist);
    float hiveTorus = inOut*hexTorus;
    
    float toreturn;
    if(a == 1.)
        toreturn = holesTorus;
    else 
        toreturn = hiveTorus;
    return toreturn;
}
float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}
vec2 GetSphereUV(vec3 p, float r)
{
    vec3 n = normalize(p);
    float x = atan(n.x, n.z)/(2.*PI) + 0.5;
    float y = 0.5 + 0.5*n.y;
    return vec2(x,y);
}
float sdSphere( vec3 p, float r )
{
    vec2 sUV = GetSphereUV(p, r);
    vec4 h = HexCoords(sUV*vec2(6.,3.3) + 100.);
    float sphereDist = length(p)-r;
    float HexSphere = sphereDist + 0.3*h.y*sin(h.y*40. + time) - h.y;
    return HexSphere;
}
vec2 GetDist(vec3 p, float a)
{
    vec2 distToReturn; 

    // torus
    vec3 torusPosNew = RotY(p - torus1Pos(), time);
    float torusDist = sdTorus1(p - torus1Pos(), torus1Size(), a);
    float torusID = 1.;

    // a big black sphere around the scene
    float worldDist = -sdSphere(p, 200.); // I did this because I dont want to discard
    float worldID = 2.;                   // the pixels that doesnt intersect with the torus, 
                                          // unless - the line in the middle will look odd
    
    // a sphere inside the torus
    vec3 spherePosNew = RotZ(spherePos(), time); // rotate around the torus
    spherePosNew = RotY(spherePosNew, time);
    // rotate around itself
    spherePosNew = RotZ(p - spherePosNew, time);
    spherePosNew = RotY(spherePosNew, time);
    
    float sphereDist = sdSphere(spherePosNew, 3.);
    float sphereID = 3.;
    
    float dist = min(torusDist,worldDist); 
    dist = min(dist, sphereDist);

    if(dist == torusDist)
        distToReturn = vec2(dist, torusID);   
    if(dist == worldDist)
        distToReturn = vec2(dist, worldID); 
    if(dist == sphereDist)
        distToReturn = vec2(dist, sphereID);
    return distToReturn;
}
vec3 RayMarch(vec3 ro, vec3 rd, float steps, float a) 
{
    vec2 dS;
    float dO;
    vec3 p;
    for(float i = 0.; i<steps; i++)
    {
        p = ro + rd * dO;
        dS = GetDist(p, a);
        if(dS.x < 0.0001) {break;}
        dO += dS.x*0.8;
    }     
    return vec3(dO,dS);
}
vec3 GetNormal(vec3 p, float a)
{
    float d = GetDist(p, a).x;
    vec2 e = vec2(.01, 0);
 
    vec3 n = d-vec3(GetDist(p-e.xyy, a).x, 
                        GetDist(p-e.yxy, a).x, 
                        GetDist(p-e.yyx, a).x);
    return normalize(n);
}
float GetLight(vec3 p, vec3 lightpos, float lightpower, float shadowstrength, float steps, float a)
{
    //vec3 lightpos = LightPos;
    //lightpos = camerapos;
    vec3 l = normalize(lightpos - p);
    vec3 n = GetNormal(p, a);
    float dif = clamp(dot(n, l*lightpower), 0., 1.);
    //dif = dot(n,l);
    float d = RayMarch(p + n*0.2, l, steps, a).x;
    if(d < length(lightpos-p)) {dif *= shadowstrength;}
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ret = vec3(0);
    
    vec2 uv_temp = uv;
    
    uv = RotZ(vec3(uv,0.), 0.4*sin(time*0.368)).xy;
    
    vec3 col = vec3(0);
 
    vec3 lookat = cameralookat();

    float zoom = 0.2;//0.5 + 0.3*sin(time*0.326);
    vec3 ro = camerapos();

    vec3 F = normalize(lookat-ro); // Forward
    vec3 R = normalize(cross(vec3(0., 1., 0.), F)); //Right
    vec3 U = cross(F, R); //Up

    vec3 C = ro + F*zoom;
    vec3 I = C + uv.x*R + uv.y*U;
    vec3 rd = normalize(I-ro);

    // this is to determine if the pixel will get the torus with the holes
    float a = 0.;
    vec2 b = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.y;
    if(uv_temp.x > b.x) {a = 1.;}
    
    vec3 d = RayMarch(ro,rd, MaxSteps, a);
    vec3 p = ro + rd*d.x;
    
    float dif = GetLight(p, LightPos(), 1., 1.,  100., a);
    //float dif = 1.;

    if(d.z == 1.) //torus painting
    {        
        vec3 col;
        vec2 tUV = GetTorusUV(p - torus1Pos(), torus1Size());
        col = Hive(tUV*vec2(6.,3.03)+1000.+torusRotSpeed());
        ret = vec3(dif);
        ret = dif*col;
    }
    if(d.z == 2.) // world painting - black
    {
        //vec2 sUV = GetSphereUV(p, 200.);
        //float stars = texture(iChannel2,sUV*5.).x;
        ret = vec3(0.);//vec3(pow(stars,13.));
    }
    if(d.z == 3.) // sphere painting
    {
        ret = vec3(dif)*vec3(0.5,0.7,0.9);
    }

    //ret = dif;
    //ret = Hive(uv*5.+10.);
    
    
    vec3 line = exp(-80.*length(uv_temp.x-b.x))*vec3(1.,1.,1.);
    vec3 lineCol = vec3(0.0); //texture(iChannel1,uv_temp*0.05 + vec2(time*0.03,time*0.07)).xyz;
    lineCol = (lineCol)*3.*vec3(0.8,1.,0.4);
    ret *= 1.-line;
    ret += line*lineCol;
    //ret = line;
    //ret = lineCol;

    
    glFragColor = vec4(ret,1.0);
}
