#version 420

// original https://www.shadertoy.com/view/3t3XWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 

Expression Plotter

Usage: PLOT_CONTINUOUS( glFragColor, uv, window, domain,
                        linecolor, side, blend, linewidth, expression );

  glFragColor - output (linear RGB)
  uv - coordinate system for window
  window - mat2, first col: window corner, second col: window size
  domain - mat2, first col: min x,y, second col: max x,y
  linecolor - RGB
  side - 0 = line, 1 = below, -1 = above (see demo)
  blend - 0=paint, 1=light-trace, 2=ink (see demo)
  linewidth - measured in units of uv.x; only for side=0
  expression - uses x as the independent variable

This file may be used and copied under the terms of the ISC License;
see end of file.  As an exception, the full permission notice may be
omitted where this file is copied within Shadertoy and the full URL,
"https://www.shadertoy.com/view/3t3XWf", is displayed within the source.

*/

// https://www.shadertoy.com/view/3t3XWf by ttg
void PLOT_CONTINUOUS_CHECK_ARGS(inout vec3 fcolor, vec2 fcoord, mat2 window,
  mat2 domain, vec3 color, int side, int blend, float linewidth) {}
#define PLOT_CONTINUOUS(_fcolor, _Afcoord, _Awindow, \
  _Adomain, _Acolor, _Aside, _Ablend, _Alinewidth, _function) \
  { \
    PLOT_CONTINUOUS_CHECK_ARGS(_fcolor, _Afcoord, _Awindow, \
      _Adomain, _Acolor, _Aside, _Ablend, _Alinewidth); \
    vec2 _fcoord = (_Afcoord); \
    mat2 _window = (_Awindow); \
    mat2 _domain = (_Adomain); \
    vec3 _color = (_Acolor); \
    int _side = (_Aside); \
    int _blend = (_Ablend); \
    float _alinewidth = (_Alinewidth); \
    vec2 _rcoord = _fcoord-_window[0]; \
    vec2 _res = _window[1]/(_domain[1]-_domain[0])/ \
        vec2(dFdx(_fcoord.x),dFdy(_fcoord.y)); \
    float _linerpa = min(10.,(_alinewidth*_res.x)*.5); \
    float _linerp = max(.5,_linerpa); \
    if (all(bvec4(greaterThan(_rcoord,vec2(0)), \
                  lessThan(_rcoord,_window[1])))) { \
      float _pixmixsum = 0.; \
      int _passes = 0; \
      if (_side==0) _passes = min(10,int(floor(_linerp))); \
      vec2 _x = _rcoord/_window[1]*(_domain[1]-_domain[0])+_domain[0]; \
      float _ylast; \
      for (int _i = -_passes-1; _i <= _passes; _i++) { \
        float offset = float(_i) ; \
        vec2 _x = _x + vec2(1,0)*offset/_res; \
        float _dx = .5/_res.x; \
        float _y1, _y2, _ddx; \
        float x = _x.x+_dx; _y1 = (_function); \
        _y2 = _ylast; _ylast = _y1; \
        if (_i==-_passes-1) continue; \
        _ddx = ((_y1-_y2)/(_dx*2.))*_res.y/_res.x; \
        float _y = (_y1+_y2)/2.; \
        float hdiff = (_y-_x.y) *_res.y; \
        if (_side==0) hdiff = \
          .7*(abs(hdiff)+.5-_linerp*sqrt(1.-pow(offset/_linerp,2.))); \
        float pixmix = hdiff/sqrt(1.+_ddx*_ddx); \
        if (_side!=0) pixmix = pixmix*sign(float(_side))+0.5; \
        if (_side==0) pixmix = 1.-pixmix; \
        pixmix = clamp(pixmix,0.,1.); \
        if (_blend==1 && _side==0) pixmix /= sqrt(1.+_ddx*_ddx); \
        if (_passes!=0 && abs(_i)==_passes) pixmix *= fract(_linerp); \
        if (_side==0) pixmix *= \
          1./(1.+max(0.,_linerp-2.)/pow(1.+_ddx*_ddx,2.0)); \
        _pixmixsum += pixmix; \
      } \
      if (_blend!=1) _pixmixsum = clamp(_pixmixsum,0.,1.); \
      if (_side==0 && _linerpa<.5) _pixmixsum*=max(0.,_linerpa*2.); \
      if (_blend==0) _fcolor = mix( _fcolor, _color, _pixmixsum ); \
      if (_blend==1) _fcolor = _fcolor + _color*_pixmixsum; \
      if (_blend==2) _fcolor = _fcolor * mix( vec3(1.), _color, _pixmixsum ); \
      _fcolor = max(vec3(0.), _fcolor); \
    } \
  }

/*
Copyright 2020 Theron Tarigo

Permission to use, copy, modify, and/or distribute this software for any 
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH 
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
*/

void main(void)
{
    vec2 f = gl_FragCoord.xy;

    vec2 uv = f/resolution.xy;

    vec3 col = vec3(0.);

    mat2 domain = transpose(mat2(-2.,2.,-2.,2.));
    
    mat2 window;
    
    window = transpose(mat2(.01,.48,.51,.48));

    PLOT_CONTINUOUS(col,uv,window,domain,vec3(1), 1, 0, 0., sin(x*2.) );
    for (float o = .4; o < 3.; o+=.4) {
        float lw = 0.006*o;
        float k = 2./(1.+.5*o);
        PLOT_CONTINUOUS(col,uv,window,domain,vec3(1), 0, 0, lw, sin(k*x)+o );
        PLOT_CONTINUOUS(col,uv,window,domain,vec3(0), 0, 0, lw, sin(k*x)-o );
    }
    
    window = transpose(mat2(.51,.48,.51,.48));

    PLOT_CONTINUOUS(col,uv,window,domain,vec3(0,1,.2), 0, 1, .02, 1.5*(x<0.?cos(exp(-x)*6.):.5*sign(cos(x*20.))) );
    
    mat2 window_ll = transpose(mat2(.01,.49,.01,.48));
    mat2 window_lr = transpose(mat2(.50,.49,.01,.48));
    mat2 domain_ll = transpose(mat2(-2.,0.,-2.,2.));
    mat2 domain_lr = transpose(mat2( 0.,2.,-2.,2.));
    
    PLOT_CONTINUOUS(col,uv,window_lr,domain_lr, vec3(1), 1, 0, 0., 2. );

    if (abs(uv.x-.5)>.01)
    for (float o = 0.; o < 1.; o+=.1) {
        float lw = 0.03;
        float k = 8.*exp(-o*.3);
        float h = 1.+3.*o;
        vec3 c = pow(.5+.5*cos(h+vec3(0,1,2)*2.094),vec3(2.));
        int blend = (uv.x<.25?1:0);
        if (abs(uv.x-.25)>.01)
        PLOT_CONTINUOUS(col,uv,window_ll,domain_ll, blend==1?c*.3:c, 0, blend, lw, cos(k*(x-2.5)-time) );
        PLOT_CONTINUOUS(col,uv,window_lr,domain_lr,               c, 0, 2,     lw, cos(k*(x-2.5)-time) );
    }
    
    glFragColor = vec4(pow(col,vec3(1./2.2)),0);
}
