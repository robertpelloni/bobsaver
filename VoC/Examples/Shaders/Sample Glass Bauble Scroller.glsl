#version 420

// original https://www.shadertoy.com/view/XtlXDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'GlassBaubleScroller' by @christinacoffin 
//
//  A Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
//    http://creativecommons.org/licenses/by-nc-sa/4.0/
//
//  remixed bits from :https://www.shadertoy.com/view/4t23RR
#define sat(x) clamp(x,0.0,1.0) 
#define time   (time+2000.)
#define TAU 6.28318530718
const vec3 BackColor    = vec3(0.11, 0.34, 0.777);
const vec3 CloudColor    = vec3(0.618,0.470,0.187);

float Func(float pX)
{
    return 0.6*(0.5*sin(0.1*pX) + 0.5*sin(0.553*pX) + 0.7*sin(1.2*pX));
}

float FuncR(float pX)
{
    return 0.95 + 0.25*(1.0 + sin(mod(40.0*pX, TAU)));
}

float Layer(vec2 pQ, float pT)
{
    vec2 Qt = 3.5*pQ;
    pT *= 0.5;
    Qt.x += pT;

    float Xi = floor(Qt.x);
    float Xf = Qt.x - Xi -0.5;

    vec2 C;
    float Yi;
    float D = 1.0 - step(Qt.y,  Func(Qt.x));

    // Disk:
    Yi = Func(Xi + 0.5);
    C = vec2(Xf, Qt.y - Yi ); 
    D =  min(D, length(C) - FuncR(Xi+ pT/80.0));

    // Previous disk:
    Yi = Func(Xi+1.0 + 0.5);
    C = vec2(Xf-1.0, Qt.y - Yi ); 
    D =  min(D, length(C) - FuncR(Xi+1.0+ pT/80.0));

    // Next Disk:
    Yi = Func(Xi-1.0 + 0.5);
    C = vec2(Xf+1.0, Qt.y - Yi ); 
    D =  min(D, length(C) - FuncR(Xi-1.0+ pT/80.0));

    return min(1.0, D);
}

void main(void)
{
    // Setup: Generate UV coordinate space to determine amount of zoom-in to properly frame the interesting bits.
    vec2 UV = 5.0*(gl_FragCoord.xy - resolution.xy/2.0) / min(resolution.x, resolution.y);    
    
    // Start with background color
    vec3 Color= BackColor;

    vec2 modUV;
    modUV.x = UV.x;
       modUV.y = 1.2-abs(UV.y);//flip to outer edges
    modUV.y *= 0.5+abs(cos(time)*0.25);// bring them together and mirror, add some bounce    
    float vertGrad = min(modUV.y,  modUV.y+1.0);//define gradient func to control distortions
    
    //16-bit style sinewave scrollerwarp
    float waveFreq_Y =39.0 * vertGrad + (15.*sin(time));
    float waveFreq_X = 0.05;
    float waveFreq_TimeScroll_Y = time * 15.0;
    float waveBlend =12.0 * vertGrad*vertGrad*vertGrad;//global scale blend
    modUV.x =  modUV.x + ( waveBlend *     (waveFreq_X * sin(vertGrad* waveFreq_Y + (waveFreq_TimeScroll_Y))) );
    
    for(float J=0.0; J<=1.0; J+=0.02)
    {
        float scrollspeedScale = 2.0;
        float Lt =  scrollspeedScale * time*(3.5  + 2.0*J)*(1.0 + 0.1*sin(2.0*J)) + 17.0*J;
        
        vec2 Lp = vec2(0.0, fract(J*0.99));        
        float L = Layer( modUV + Lp, Lt);

        // Blur and color:
        float Blur = 0.1*(0.5*abs(2.0 - 1.0*J))/(1.50 - 1.0*J);
        
        // ccoffin: smoothstep to negative and outside 0-1 bounds to create extra stylized interactions to fake refract
        float V = mix( -0.05, 1.8950, 1.0 - smoothstep( -0.10, 0.01 +0.2*Blur, L ) );
        vec3 Lc=  mix( CloudColor, vec3(1.0), J);

        Color =mix(Color, Lc,  V);
    }

    Color.rgb = Color.bgr;
    Color.b = sat( Color.b );
    Color.b += 0.95*abs(UV.y*UV.y);
    
    // Color.gbr = sin(Color.rgb*0.5);// alternate stylized sin palette
    
    glFragColor = vec4(Color, 1.0);
}

