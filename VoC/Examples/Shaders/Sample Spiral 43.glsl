#version 420

// original https://www.shadertoy.com/view/fl23Rt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*0.1
mat2 r2d(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

//https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

 

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 tv = uv;
    vec2 R = resolution.xy;
    float ar = R.x/R.y;
    //tv -= 0.5;
    //tv = vec2((length(tv)), atan(tv.x,tv.y));
    //tv.y = abs(tv.y+time*0.02);
    //tv *= r2d(time*0.91);
    //tv = vec2(tv.x*sin(tv.y),tv.x*cos(tv.y));
    //tv += 0.5;
    //tv = abs(tv-0.5)+0.5;
    //vec3 bak = texture(texture1,tv).rgb;
    uv -= 0.5;
    uv.x *= ar;
    //uv *= 0.2;
    //uv += 0.5;
    uv *= 1.;
    float ac = length(uv);
    float udt = time*0.2;
    vec2 uvd = uv/mix(vec2(sin(udt),cos(udt*0.9238)*9.)*0.5,vec2(1.,0.5),1.-ac);
    //uv = mix(uvd,uv,sin(time*0.1+1.)*0.5+0.5);
    //uv *= (1.-ac)*(1.-ac);
    //uv *= vec2(sin(udt),cos(udt*0.9238)*4.)*0.2;
    //uv *= r2d(ac*2.+time*0.5);
    //uv.x *= 0.1;
    float c = length(uv);
    float lc = log(c)*0.093;
    //uv *= 20.1;
    float scrolltime = time*0.;
    float zoomtime = time*0.9;
    //scrolltime += sin(lc*9+time*1)*0.1;
    //uv /= c;
    //uv.x += time;
    tv -= 0.5;
    tv *= 1.+lc*0.09;
    tv += 0.5;
    //vec3 bakd = texture(texture1,tv).rgb;
    vec2 cuv = vec2(lc,atan(uv.x,uv.y)/6.27831853071);
    //uv.x *= 0.9;
    //uv = mix(uv,cuv,sin(time)*0.5+0.5);
    //uv *= 0.1;
    //cuv.x *= 0.1;
    uv = cuv;
    //uv *= 0.5;
    
    uv.x *= 1.;
    uv.y *= 1.;
    vec2 uvb = uv;
    //uv *= 0.1;
    uv.x -= zoomtime*0.2;
    //uv.x *= 1.7;
    vec2 uvc = uv+0.5;
    //uv.y /= 6.28318;
    uv = fract(uv-0.5);
    //uv.x += time;
    //uvc = fract(uvc-0.5);
    //uv = vec2(lc,atan(uv.x,uv.y));
    //uv.x *= 0.4;
    vec3 col = vec3(0.);
    float ct = 20.;
    //uv *= r2d(lc);
    float b = 0.;
    //uv *= 0.6;
    vec2 rud = uv;
    uv *= r2d(1./ct);
    uvc *= r2d(1./ct);
    uvb *= r2d(1./ct);
    //uv *= 0.3;
    //uv.x *= 0.03;
    //uv *= r2d((3.141/180.)*(90/ct));
    vec2 uvf = floor(uv*ct)/ct;
    vec2 fr = fract(rud);
    //uvc.x += .9;
    float uvxf = floor(uvc.x*ct)/ct;
    float uvtf = floor(uvc.x*ct);
    float sy = uvxf;
    sy -= ((uvc.y)/ct);
    //uvtf = uvxf;
    //uvtf -= sin(((uvc.y)/ct)*time);
    float dist = (sin(c*8.+time*23.)*0.004);
    //sy += sin(sy*0.0002)*time;
    //sy += sin(floor(uvc.x*ct))*time*0.5;
    //sy -= sin(uvxf/3.14159)*time;
    //sy += dist*(dist+lc*2);
    //sy += sin(uvxf*4.14+time*0.1);
    //sy += sin(uvtf*time*0.01)*time*0.51;
    //sy = ((fract(sy*400.)/400.)-(0.5/40))+sy;
    //sy -= 0.5/40;
    //sy = abs(fract(sy))-0.55;
    //sy += sin(floor(uvc.x*ct)*62.9+2)*time*0.3;
    sy += sin(sy*0.5)*1.;
    sy *= 01.25;
    //sy += sin(uvc.x*02.2)*0.01;
    //sy += sin(time*0.5)*2.;
    //sy *= r2d(time);
    //sy = sin(sy*4)*40;
    sy -= scrolltime*0.05;
    //sy += time*c*0.00002;
    //sy *= c;
    //sy += (rud.y-0.5);
    //sy -= (-rud.y-time)/ct;
    //sy = fract(sy);
    //sy *= 2;
    vec2 uvs = fract(vec2((uvc.x)*20.,sy));
    //uvs.y *= 0.5;
    //uvs.y += sin(uvc.x*0.03);
    uvs.y = abs(uvs.y-0.5)+0.5;
    uvs.y *= ct*ct;
    
    //uvs.x *= 1./ct;
    //uvs.y = abs(uvs.y)-1.;
    //sy += (-rud.y)/ct;
    //sy = rud.y;
    //uvf -= uv.y*0.05;
    //uvf *= 0.9;
    //uvf += ((rud.y)/ct);
    //uvf += abs((rud.y)/ct);
    //b *= 0.;
    //b = (rud.y);
    //b = 1.-smoothstep(0.,0.02,abs(uvs.x-0.5)-0.4);
    b = 1.-smoothstep(0.,0.06,abs(uvs.x-0.5)-0.1);
    vec2 uvg = uvs;
    //uvg.x += 0.3;
    //uvg.y += 2.;
    uvg.y += sin(sin(sin(uvg.x*3.141)+uvg.y*0.004)*3.)*0.2;
    //uvg.x = abs(uvg.x);
    //uvg.x *= 2.2;
    uvg.y *= 01.5;
    //uvg.x *= (sin(sin(uvs.y*0.01)*2.)*0.5+1.)*3.;
    uvg = fract(uvg);
    //uvg.x *= 2.;
    uvg = abs(uvg-0.5);
    //uvg *= 3.;
    //uvg.y += c;
    uvs.y *= 0.2;
    //uvg.x *= 1*sin(uvs.y*0.1);
    uvg -= 0.5*sin(uvs.y*0.01);
    uvg *= r2d(uvs.y*sin(uvs.y*0.00101+0.)*2.);
    uvg = abs(uvg)-0.2;
    uvg *= r2d(uvs.y*cos(uvs.y*0.001)*0.1);
    uvg = abs(uvg)-0.2;
    uvg *= sin(uvs.y*0.01)*0.5+0.8;
    uvg *= r2d(uvs.y*sin(uvs.y*0.0001)*1.);
    for (int i=0;i<5;i++) {
        uvg *= r2d(uvs.y*cos(uvs.y*0.001)*0.1);
        uvg = abs(uvg)-0.2;
    }
    uvg += 0.5;
    //uvg.x += lc;
    b *= smoothstep(0.02,0.04,abs(uvg.x-0.5));
    float bh = smoothstep(1.,0.0,abs(uvg.x-.5));;
    //b *= smoothstep(0.02,0.01,abs(uvg.x-0.5));
    //uvs *= 10.;
    
    //col.rg = sin(uvs);
    col = vec3(b);
    //col = sin(col);
    col = rgb2hsv(col);
    //col = hsv2rgb(vec3((uvs.y*0.02)+bh*10+time*0.1,1.,(sin(uvs.y*0.1)*0.3+0.7)*col.b));
    //col = hsv2rgb(vec3((uvs.y*0.02)+bh*10+time*0.1,1.,(sin(uvs.y*0.1)*0.3+0.7)*col.b));
    
    col = hsv2rgb(vec3((uvs.y*0.02)+bh*10.+time*0.1,1.,((sin(uvs.y*sin(uvs.x*02.2+0.6)*.15+4.5)*.5+0.5)*0.5+0.5)*b));
    //col = hsv2rgb(vec3((uvs.y*0.02)+bh*10+time*0.1,1.,(sin(uvs.y*0.1)*0.3+0.7)*col.b));
    //bak = mix(bak,bakd,0.08);
    
    //if (b < 0.95) {
        //col = bak*0.997;
        //col 
        //col = fract(col+0.01);
        //col = mix(col,bak,01.4);
    //}
    //col = mix(col,bak,0.6*(1.-((lc+1)*.15)));
    //col = mix(vec3(b),col,0.4);
    //col.rg = sin(uvs*30);
    //col = vec3(sin(uvs.y)+sin(uvs.x));
    //col.rg = sin(uvs*6+time*2);
    //col.b = sin((uv.x+uv.y)*9*4);
    //col.rg = vec2(sin(vec2(uvc.x,uvx.y)/2));
    //col.rg = uv;
    //col.rg = uv*0.2;
    //col.b = sy+time*0.5;
    //col.b = sin(sy*0.7);
    //col.b = sy;
    //col.r = rud.y;
    //col.b = sin(sy*220)*0.3+sin(sy);
    //col = vec3(abs(uvc.y-0.5));
    //col.b = sin(col.b*2000)+sin(col.b*4.);
    //col.b = sin(col.b+time);
    //col.b = sin(col.b*3.14)*0.5+0.5;
    //col.b = sin(col.b*62.9+1.)+sin(col.b*2+time)*0.5;
    //col = vec3(sin(uv.x*20));
    glFragColor = vec4(col,1.0);
}
