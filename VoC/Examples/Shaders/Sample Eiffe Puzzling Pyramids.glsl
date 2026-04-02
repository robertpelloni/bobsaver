#version 420

// original https://www.shadertoy.com/view/XdSSWc#

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Puzzling Pyramids by eiffie

/*
The pharaoh Djedefptah sat before the 4 pyramid builders and spoke: 
“My astronomers warn that our great pyramids are at risk of being flooded by the rising Nile
at the next full moon 20 days from now. My plan is to move the pyramids to higher ground 
near Giza. Each of you will be given 2 teams of 100 men. One team will move the top of your 
pyramid then rest a day while the other team moves a slab off the bottom. If any team fails 
to move their slab in a day they will be executed. They must always place the slab they have 
moved on top of the other pile with no stopping to rest.“ He turned to Qemeru the builder of 
Menkaure’s pyramid and asked. “Your pyramid is smallest. If we section it into 3 slabs how 
many days will it take to move?” Qemeru had a concerned look. He knew it wasn’t wise to 
correct the pharaoh but his rules would only make the job harder. The Pharaoh asked more 
forcefully. “Can you move it in 20 days!” Qemeru answered after some thought.  “I can have 
it moved in 5.” The pharaoh was pleased and continued: “Good and you Suret the builder of 
Khafra’s Pyramid. If we section it into 4 slabs how many days will it take you?” Suret 
thought for a bit and replied: “I believe 8 days will do.” At this the old man Hemon spoke 
up. “13 days for me if we section Khufu’s Pyramid into 5 slabs.” “Excellent!” Replied the 
pharaoh as he turned to the greatest pyramid builder of them all. “Billy how about you? 
Surely you can save the grand pyramid you have constructed for me before it sinks into the 
delta. If we section it into 6 slabs can it be moved in 20 days?” Billy scratched his head 
nervously. He wasn’t sure how the others were coming up with these numbers. He tore a piece 
of papyrus into little slabs and began fumbling with the scraps. “We are all waiting Billy…” The pharaoh said as he grew impatient.
What should Billy’s answer be?

ANSWER:
YX LYKVSP LOF FXL, TVZ OSS ZYX JXB YX PKXLB’Z SRIX KB ZXOJ 1 OBP LOF ZYX TYOUOKY HODX ZYXJ 
ZYX 17ZY POF KQQ
*/
    
#define size resolution

int GetPile(int i,float n){//from movAX13h's chr function
    return int(mod(n/exp2(float(i)), 2.0));
}
float fpn(vec2 p,float a){p=sin(p+2.4*sin(p.yx));return 0.5+a*(p.x-p.y);}
vec2 rotate(vec2 v, float angle) {return cos(angle)*v+sin(angle)*vec2(v.y,-v.x);}
float DESlab(vec2 p, int i){
    p=rotate(p,sin(float(i)*4.0)*0.1);
    return max(abs(p.x)-float(i+1)*0.05+p.y*0.5,abs(p.y)-0.05);
}
float DEArrow(vec2 p){
    return abs(p.x)-p.y+0.44;
}
#define SLABS 5
int PopTop(inout int p[SLABS], inout int t){
    int s=0;
    for(int i=0;i<SLABS;i++){
        if(i==t-1)s=p[i];
    }
    t-=1;
    return s;
}
int PopBottom(inout int p[SLABS], inout int t){
    int s=p[0];
    p[0]=p[1];p[1]=p[2];p[2]=p[3];p[3]=p[4];
    t-=1;
    return s;
}
void Push(int s, inout int p[SLABS], inout int t){
    for(int i=0;i<SLABS;i++){
        if(i==t)p[i]=s;
    }
    t+=1;
}
void main() {
    float gt=time,ans=8.0;
    int p1[SLABS],p2[SLABS],t1=3,t2=0,steps=5;
    p2[0]=0;
    p2[1]=0;
    p2[2]=0;
    p2[3]=0;
    p2[4]=0;
    if(gt>15.0){gt-=15.0;ans=2600.0;steps=13;t1=5;}
    else if(gt>6.0){gt-=6.0;ans=24.0;steps=8;t1=4;}
    for(int i=0;i<SLABS;i++){p1[i]=t1-1-i;}//init pile 1
    int gs=int(min(floor(gt),float(steps))),s=0,j=0;
    bool top=true;
    for(int i=0;i<13;i++){//shuffle piles
        if(i<gs){
            j=GetPile(i,ans);
            if(j==0){
                if(top)s=PopTop(p1,t1);
                else s=PopBottom(p1,t1);
                Push(s,p2,t2);
            }else{
                if(top)s=PopTop(p2,t2);
                else s=PopBottom(p2,t2);
                Push(s,p1,t1);
            }
            top=!top;
        }
    }
    //draw piles
    vec2 uv=gl_FragCoord.xy/vec2(size);
    bool drawAnim=(gt>0.5 && gt<float(steps)+0.5);
    float d=100.0,st=fract(gt);
    for(int i=0;i<SLABS;i++){
        if(i<t1){
            float x=0.0,y=0.0;
            if(st<0.5 && drawAnim){
                if(st<0.25 && p1[i]==s){
                    x=0.5-st*2.0;
                    if(top){y=-float(i)*0.15*(0.25-st)*4.0;}
                    else{y=float(t2-i)*0.15*(0.25-st)*4.0;}
                }else if(j==0 && top)y=0.15-(max(st,0.25)-0.25)*0.6;
            }
            d=min(d,DESlab(uv-vec2(0.25+x,0.2+float(i)*0.15+y),p1[i]));
        }
        if(i<t2){
            float x=0.0,y=0.0;
            if(st<0.5 && drawAnim){
                if(st<0.25 && p2[i]==s){
                    x=0.5-st*2.0;
                    if(top){y=-float(i)*0.15*(0.25-st)*4.0;}
                    else{y=float(t1-i)*0.15*(0.25-st)*4.0;}
                }else if(j==1 && top)y=0.15-(max(st,0.25)-0.25)*0.6;
            }
            d=min(d,DESlab(uv-vec2(0.75-x,0.2+float(i)*0.15+y),p2[i]));
        }
    }
    //vec3 col=texture2D(iChannel0,uv).rgb*1.5-texture2D(iChannel0,uv-vec2(0.0036)).rgb*0.7;
    vec3 col=vec3(0.0,0.0,0.0);
    col=mix(vec3(1.0)*fpn(uv*40.0,0.5),col,smoothstep(0.0,0.005,d));
    col=mix(2.0*vec3(1.0,0.9,0.5)*fpn(uv*40.0,0.01),col,smoothstep(0.0,0.005,d));
    if(drawAnim){
        if(st<0.5)top=!top;
        vec2 p=uv-vec2(0.5);
        if(!top)p.y=-p.y;
        d=DEArrow(p);
        col=mix(vec3(1.0,0.5+0.1*sign(p.x),0.5),col,smoothstep(0.0,0.005,d));
    }
    
    glFragColor = vec4(clamp(col*fpn(uv*5.0,0.125),0.0,1.0),1.0);
}

