#version 420

//various attempts at video feedback like results

uniform sampler2D backbuffer;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//uncomment one of these to see the variations included
//#define variation1
//#define variation2
//#define variation3
//#define variation4
//#define variation5
#define variation6
//#define variation7
//#define variation8

float pi=3.141592;
float pidiv180=pi/180.0;
float pw,ph; //width and height of each pixel

//returns a point zoomed closer to the center of image
vec2 ZoomToCenter(vec2 currentpos, float zoomrate)
{
    vec2 Delta = vec2(1.0)/resolution;
    vec2 uv = gl_FragCoord.xy / resolution;
    float deltax = gl_FragCoord.x-resolution.x/2.0;
    float deltay = gl_FragCoord.y-resolution.y/2.0;
    float angleradians = atan(deltay,deltax)+3.14159265;
    float newx = gl_FragCoord.x + cos(angleradians)*zoomrate;
    float newy = gl_FragCoord.y + sin(angleradians)*zoomrate;
    return vec2(newx,newy)/resolution;
}

//returns a point zoomed closer to the mouse
vec2 ZoomToMouse(vec2 currentpos, float zoomrate)
{
    vec2 Delta = vec2(1.0)/resolution;
    vec2 uv = gl_FragCoord.xy / resolution;
    float deltax = gl_FragCoord.x/resolution.x-mouse.x;
    float deltay = gl_FragCoord.y/resolution.y-mouse.y;
    float angleradians = atan(deltay,deltax)+3.14159265;
    float newx = gl_FragCoord.x + cos(angleradians)*zoomrate;
    float newy = gl_FragCoord.y + sin(angleradians)*zoomrate;
    return vec2(newx,newy)/resolution;
}

float randb(vec2 co){
    return (fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) > 0.75) ? 1.0 : 0.0;
}

//blur the backbuffer texture
//standard averaging of pixel and 8 neighbors
vec3 blur(vec2 uv, float pw, float ph) {
    vec4 C = texture2D(backbuffer,uv);
    vec4 E = texture2D(backbuffer,vec2(uv.x + pw, uv.y) );
    vec4 N = texture2D(backbuffer,vec2(uv.x, uv.y + ph) );
    vec4 W = texture2D(backbuffer,vec2(uv.x - pw, uv.y) );
    vec4 S = texture2D(backbuffer,vec2(uv.x, uv.y - ph) );
    vec4 NE = texture2D(backbuffer,vec2(uv.x + pw, uv.y + ph) );
    vec4 NW = texture2D(backbuffer,vec2(uv.x - pw, uv.y + ph) );
    vec4 SE = texture2D(backbuffer,vec2(uv.x + pw, uv.y - ph) );
    vec4 SW = texture2D(backbuffer,vec2(uv.x - pw, uv.y - ph) );
    vec4 col=(C+E+N+W+S+NE+NW+SE+SW)/9.0;
    return vec3(col);
}

//basically just a lookup from a texture with GL_LINEAR (instead of the active GL_NEAREST method for the backbuffer)
//resembled in shader code - surely not very efficient, but hey it looks much better and works on Float32 textures too!
vec4 bilinear(sampler2D sampler, vec2 uv){
    vec2 pixelsize = 1./resolution;
    vec2 pixel = uv * resolution + 0.5;
    vec2 d = pixel - floor(pixel) + 0.5;
    pixel = (pixel - d)*pixelsize;
    
    vec2 h = vec2( pixel.x, pixel.x + pixelsize.x);
    if(d.x <= 0.5)
        h = vec2( pixel.x, pixel.x - pixelsize.x);
    
    vec2 v = vec2( pixel.y, pixel.y + pixelsize.y);
    if(d.y <= 0.5)
        v = vec2( pixel.y, pixel.y - pixelsize.y);
    
    vec4 lowerleft = texture2D(sampler, vec2(h.x, v.x));
    vec4 upperleft = texture2D(sampler, vec2(h.x, v.y));
    vec4 lowerright = texture2D(sampler, vec2(h.y, v.x));
    vec4 upperright = texture2D(sampler, vec2(h.y, v.y));
    
    d = abs(d - 0.5);
    
    return mix( mix( lowerleft, lowerright, d.x), mix( upperleft, upperright, d.x),    d.y);
}

//sharpen the backbuffer texture
vec3 sharpen(vec2 uv, float pw, float ph, float amount) {
    vec4 col1=texture2D(backbuffer,uv);
    vec4 col2=texture2D(backbuffer,uv+pw);
    vec3 col3=vec3((col1+amount*(col1-col2)));
    return vec3(col3);
}

void Rotate2(float RotAng, float x, float y, inout float Nx, inout float Ny) {
    float SinVal;
    float CosVal;
    RotAng*=pidiv180;
    SinVal=sin(RotAng);
    CosVal=cos(RotAng);
    Nx=x*CosVal-y*SinVal;
    Ny=y*CosVal+x*SinVal;
}

void Rotate(float RotAng, float x, float y, float ox, float oy, inout float Nx, inout float Ny) {
    Rotate2(RotAng,x-ox, y-oy, Nx, Ny);
    Nx+=ox;
    Ny+=oy;
}

//standard non weighted blur
vec3 BoxBlur(sampler2D sampler, vec2 uv, int radius){
    vec3 c;
    for (int y=-radius;y<radius;y++) {
        for (int x=-radius;x<radius;x++) {
            c+=vec3(texture2D(sampler,vec2(uv.x+pw*x,uv.y+ph*y)));
        }
    }
    c=c/(radius*2.0*radius*2.0);
    return c;
}

void main(void) {
    vec2 p = ( gl_FragCoord.xy );
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 originaluv = gl_FragCoord.xy / resolution.xy;
    float pw = 1.0/resolution.x;
    float ph = 1.0/resolution.y;
    vec3 c,col;
    
///////////////////////////////////////////////////////////////////////////////
// Variation 1
///////////////////////////////////////////////////////////////////////////////
#ifdef variation1
    //control variables
    float zoom_rate=0.75;
    float pen_radius=50.0;
    float contrast_amount=150.0;
    float brightness_amount=100.0;
    float noise_amount=0.0;

    uv=abs(uv-1.0);
    
    if(length(mouse*resolution-p) < pen_radius )
    {
        c=vec3(1.0-randb(p+time));
    } else {
        col=blur(uv,pw,ph);
        //col=bilinear(backbuffer,uv);
        //brightness
        col=col*brightness_amount/100.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //noise
        col+=randb(p+time*4.0)*noise_amount;
        c=col;
    }
    
    uv=ZoomToCenter(uv,zoom_rate*2.0);
    uv=ZoomToMouse(uv,zoom_rate*1.0);
    
    col=1.0-min(texture2D(backbuffer,uv).xyz,c);
    
#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 2
///////////////////////////////////////////////////////////////////////////////
#ifdef variation2
    //control variables
    float zoom_rate=2.75;
    float pen_radius=20.0;
    float contrast_amount=500.0;
    float brightness_amount=130.0;
    float noise_amount=0.1;
    float rotation_degrees=0;
    float blah;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    //uv=abs(uv-1.0);
    
    if(length(mouse*resolution-p) < pen_radius )
    {
        //col=vec3(1.0-randb(p+time));
        col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
        //col=vec3(1.0,1.0,1.0);
        //col=vec3(random1,random1,random1);
    } else {
        col=blur(uv,pw,ph);
        //col=bilinear(backbuffer,uv);
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //brightness
        col=col*brightness_amount/100.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
    }    
#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 3
///////////////////////////////////////////////////////////////////////////////
#ifdef variation3
    //control variables
    float zoom_rate=1.05;
    float pen_radius=20.0;
    float contrast_amount=250.0;
    float brightness_amount=160.0;
    float noise_amount=0.1;
    float rotation_degrees=0.0;
    float blah;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    uv=abs(uv-1.0);
    
    if(length(mouse*resolution-p) < pen_radius )
    {
        //col=vec3(1.0-randb(p+time));
        col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
        //col=vec3(1.0,1.0,1.0);
        //col=vec3(random1,random1,random1);
    } else {
        col=blur(uv,pw,ph);
        //col=bilinear(backbuffer,uv);
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //brightness
        col=col*brightness_amount/100.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.3);

#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 4
///////////////////////////////////////////////////////////////////////////////
#ifdef variation4
    //control variables
    float zoom_rate=1.01;
    float pen_radius=30.0;
    float contrast_amount=10.0;
    float brightness_amount=105.1;
    float noise_amount=0.0;
    float rotation_degrees=1;
    float blah;
    vec3 noise;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    //uv=abs(uv-0.5);
    
    if(length(mouse*resolution-p) < pen_radius )
    {
        col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
    } else {
        //noise
        noise=vec3(randb(p+time*4.0)*noise_amount-noise_amount/2.0);
        col=vec3(bilinear(backbuffer,uv))+noise;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //brightness
        col=col*brightness_amount/100.0;
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.95);

#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 5
///////////////////////////////////////////////////////////////////////////////
#ifdef variation5
    //control variables
    float zoom_rate=1.1;
    float pen_radius=1.0;
    float contrast_amount=100.0;
    float brightness_amount=110.1;
    float noise_amount=0.2;
    float rotation_degrees=0.0;
    float sharpen_amount=0.7;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    //uv=abs(uv-0.5);
    
    if(length(mouse*resolution-p) < pen_radius )
    {
        col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
    } else {
        //blur backbuffer current pixel
        vec4 c1=bilinear(backbuffer,uv);
        //blur backbuffer pixel to the right of current pixel
        vec4 c2=bilinear(backbuffer,uv+pw);
        //use the blurred results to sharpen the color
        col=vec3((c1+sharpen_amount*(c1-c2)));
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //brightness
        col=col*brightness_amount/100.0;
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.5);

#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 6
///////////////////////////////////////////////////////////////////////////////
#ifdef variation6
    //control variables
    float zoom_rate=0.6;
    float pen_radius=1.0;
    float contrast_amount=100.0;
    float brightness_amount=130.1;
    float noise_amount=0.2;
    float rotation_degrees=181.0;
    float sharpen_amount=0.7;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    uv=abs(uv-1.0);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    
    if(length(mouse*resolution-p) < pen_radius )
    {
        //col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
        col=vec3(randb(p+time));
    } else {
        //blur backbuffer current pixel
        vec4 c1=bilinear(backbuffer,uv);
        //blur backbuffer pixel to the right of current pixel
        vec4 c2=bilinear(backbuffer,uv+pw);
        //use the blurred results to sharpen the color
        col=vec3((c1+sharpen_amount*(c1-c2)));
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //brightness
        col=col*brightness_amount/100.0;
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.5);

#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 7
///////////////////////////////////////////////////////////////////////////////
#ifdef variation7
    //control variables
    float zoom_rate=2.3;
    float pen_radius=30.0;
    float contrast_amount=30.0;
    float brightness_amount=89.0;
    float noise_amount=0.1;
    float rotation_degrees=180.0;
    float sharpen_amount=0.1;
    int blur_radius=3;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    //uv=abs(uv-1.0);

    Rotate(rotation_degrees,uv.x,uv.y,0.5,0.5,uv.x,uv.y);

    
    if(length(mouse*resolution-p) < pen_radius )
    {
        //col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
        //col=vec3(randb(p+time));
        col=vec3(1.0);
    } else {
        //blur backbuffer current pixel
        vec3 c1=BoxBlur(backbuffer,uv,blur_radius);
        //blur backbuffer pixel to the right of current pixel
        vec3 c2=BoxBlur(backbuffer,uv+pw,blur_radius);
        //use the blurred results to sharpen the color
        col=vec3((c1+sharpen_amount*(c1-c2)));
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //brightness
        col=col*brightness_amount/100.0;
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.3);

#endif

///////////////////////////////////////////////////////////////////////////////
// Variation 8
///////////////////////////////////////////////////////////////////////////////
#ifdef variation8
    //control variables
    float zoom_rate=3.7;
    float pen_radius=5.0;
    float contrast_amount=-5.0;
    float brightness_amount=105.0;
    float noise_amount=0.05;
    float rotation_degrees=5.0;
    float sharpen_amount=0.5;
    int blur_radius=15;

    //uv=ZoomToCenter(uv,zoom_rate);
    uv=ZoomToMouse(uv,zoom_rate);

    //uv=abs(uv-1.0);

    Rotate(rotation_degrees,uv.x,uv.y,mouse.x,mouse.y,uv.x,uv.y);

    
    if(length(mouse*resolution-p) < pen_radius )
    {
        //col=vec3(randb(p+time),randb(p+time*2.0),randb(p+time*3.0));
        col=vec3(randb(p+time));
        //col=vec3(1.0);
    } else {
        //blur backbuffer current pixel
        vec3 c1=BoxBlur(backbuffer,uv,blur_radius);
        //blur backbuffer pixel to the right of current pixel
        vec3 c2=BoxBlur(backbuffer,uv+pw,blur_radius);
        //use the blurred results to sharpen the color
        col=vec3((c1+sharpen_amount*(c1-c2)));
        //noise
        col+=randb(p+time*4.0)*noise_amount-noise_amount/2.0;
        //contrast
        col=col+((col-0.5)*contrast_amount/100.0);
        //brightness
        col=col*brightness_amount/100.0;
    }    

    col=mix(texture2D(backbuffer,originaluv).xyz,col,0.3);

#endif

    //update the pixel
    glFragColor = vec4(col,1.0);
    
    
    
}
