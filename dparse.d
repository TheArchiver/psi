import std.uni, std.array, std.string, std.conv, std.algorithm, std.range;
import dexpr,util;

DExpr dParse(string s){ // TODO: this is work in progress, usually updated in order to speed up debugging
	struct DParser{
		string code;
		void skipWhitespace(){
			while(!code.empty&&code.front.isWhite())
				next();
		}
		dchar cur(){
			skipWhitespace();
			if(code.empty) return 0;
			return code.front;
		}
		void next(){ code.popFront(); }
		void expect(dchar c){
			if(cur()==c) next();
			else throw new Exception("expected '"~to!string(c)~"' at \""~code~"\"");
		}
		
		DExpr parseDIvr(){
			expect('[');
			auto exp=parseDExpr();
			DIvr.Type ty;
			switch(cur()) with(DIvr.Type){
				case '=': next(); expect('0'); ty=eqZ; break;
				case '≠': next(); expect('0'); ty=neqZ; break;
				case '<': next(); expect('0'); ty=lZ; break;
				case '≤': next(); expect('0'); ty=leZ; break;
				default: expect('<'); assert(0);
			}
			expect(']');
			return dIvr(ty,exp);
		}
		DExpr parseDDelta(){
			expect('δ');
			expect('[');
			auto expr=parseDExpr();
			expect(']');
			return dDelta(expr);
		}
		
		DExpr parseDInt(){
			expect('∫');
			expect('d');
			auto iVar=parseDVar();
			auto iExp=parseDExpr();
			return dInt(iVar,iExp);
		}

		DExpr parseDℕ()in{assert('0'<=cur()&&cur()<='9');}body{
			ℕ r=0;
			while('0'<=cur()&&cur()<='9'){
				r=r*10+cast(int)(cur()-'0');
				next();
			}
			return dℕ(r);
		}

		bool isIdentifierChar(dchar c){
			if(c=='δ') return false; // TODO: this is quite crude
			if(c.isAlpha()) return true;
			if(lowDigits.canFind(c)) return true;
			return false;
		}

		string parseIdentifier(){
			skipWhitespace();
			string r;
			while(!code.empty&&isIdentifierChar(code.front)){
				r~=code.front;
				code.popFront();
			}
			if(r=="") expect('ξ');
			return r;
		}

		DVar parseDVar(){
			string s=parseIdentifier();
			return dVar(s);
		}

		DExpr parseBase(){
			if(cur()=='[') return parseDIvr();
			if(cur()=='δ') return parseDDelta();
			if(cur()=='∫') return parseDInt();
			if(cur()=='⅟'){
				next();
				return 1/parseFactor();
			}
			if('0'<=cur()&&cur()<='9')
				return parseDℕ();
			if(cur()=='e'){
				next();
				return dE;
			}
			if(cur()=='π'){
				next();
				return dΠ;
			}
			return parseDVar();
		}

		DExpr parseDPow(){
			if(cur()=='('){
				next();
				auto r=parseDExpr();
				expect(')');
				return r;
			}
			DExpr e=parseBase();
			if(cur()=='^'){
				next();
				return e^^parseFactor();
			}
			if(highDigits.canFind(cur())){
				ℕ exp=highDigits.indexOf(cur());
				next();
				assert(!highDigits.canFind(cur()),"TODO");
				return e^^exp;
			}
			return e;
		}

		DExpr parseFactor(){
			if(cur()=='-'){
				next();
				return -parseFactor();
			}
			return parseDPow();
		}

		DExpr parseMult(){
			DExpr f=parseFactor();
			while(cur()=='·'){
				next();
				f=f*parseFactor();
			}
			return f;
		}

		DExpr parseAdd(){
			DExpr s=parseMult();
			while(cur()=='+'){
				next();
				s=s+parseMult();
			}
			return s;
		}

		DExpr parseDExpr(){
			return parseAdd();
		}
	}
	return DParser(s).parseDExpr();
}