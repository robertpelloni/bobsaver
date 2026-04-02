// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// scribble blue in tweets of two
//
// improved + golfed down ballpoint effect
//
// check "https://10xfx.com" for this and more effects for AfterEffects and OpenFX

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

#define R resolution.xy

#define V(p) texture2D(image,(p)/R,.5).y

void main(void)
{
	vec4 c = gl_FragColor;
	vec2 f = gl_FragCoord.xy;
	
	float S=sqrt(R.x)/30.,h,s;
    c-=c-1.;
    vec2 g,d=R/2E2,p,q,v,i,e=vec2(d.x*.2,0);
    for(int j=0;j<3000;j++)
    {
        int k=j/16;
    	if(j%16==0) { i=floor(f/d)+vec2(k%13,k/13)-6.; s=mod(i.y,2.)-.5; p=(i+s)*d; v-=v; }
	    q=p;
        g=V(p)-vec2(V(p-e),V(p-e.yx));
        h=pow(dot(g,g),.3)*20.;
        v=mix(v, 
              mat2( cos( .8*vec4(4,2,6,4) + atan(h)*1.3*s+s ) ) * normalize(g), 
              atan(h*h/8.));
        p+=v*d.x;
	    g=q-p; q=f-p; float l=length(g); g/=l; h=dot(q,g);
		c-=vec4(.3,.2,.1,0)*max(S-max(S-min(l-h,h),abs(dot(q,g.yx*vec2(1,-1)))),0.);
    }
	glFragColor = c;
}
