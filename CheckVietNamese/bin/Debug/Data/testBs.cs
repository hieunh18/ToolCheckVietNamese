//---------------------------------------------------------------------------
//
//  System			:	iWAOシステム
//  Class Name		:	NIF05NetOdrCancelBs
//  Overview		:	NET注文キャンセル登録sai
//  Designer		:	ChanhNV＠SSV
//  Programmer		:	ChanhNV＠SSV
//  Created Date	:	YYYY/MM/DD
//
#region ----------< History >------------------------------------------------
//	ID				:	
//	Designer		:	
//	Programmer		:	
//	Updated Date	:	
//	Comment			:	
//	Version			:	
//---------------------------------------------------------------------------
#endregion

#region using

// .Net Framwork
using System;
using System.Data;
using System.Reflection;

// EFSA Framwork
using Jp.Co.Unisys.EFSA.Core.Base;
using Jp.Co.Unisys.EFSA.Core.Context;
using Jp.Co.Unisys.EFSA.Core.ExceptionManagement;
using Jp.Co.Unisys.EFSA.Core.Log;

// 業務部品toi
using Jp.Co.Unisys.FF3.Constants;
using Jp.Co.Unisys.FF3.Da.CMN;
using Jp.Co.Unisys.FF3.Da.NIF._05;

#endregion

namespace Jp.Co.Unisys.FF3.Bs.NIF._05
{
	/// <summary>
	/// NET注文キャンセル登録Bs ôi
	/// </summary>
	public class NIF05NetOdrCancelBs : CommonBase
	{
		#region 定数定義

		/// <summary>
		/// 数値0
		/// </summary>
		private const int INT_ZERO = 0;

		#endregion

		#region コンストラクタ

		/// <summary>
		/// コンストラクタ
		/// </summary>
		public NIF05NetOdrCancelBs()
		{
		}

		#endregion

		#region 注文状態確認

		/// <summary>
		/// 注文状態確認
		/// </summary>
		/// <param name="odrNo">注文番号ê</param>
		/// <param name="userCd">ユーザコード</param>
		/// <param name="updateJobMod">更新画面名</param>
		/// <param name="odrHstat">注文ヘダー状態</param>
		/// <param name="errCode">エラーコード</param>
		public void NetConfirmOdrHdrStat(	long odrNo,
											string userCd,
											string updateJobMod,
											out string odrHstat,
											out int errCode )
		{
			// NET注文キャンセル登録特殊データアクセス
			NIF05NetOdrCancelDa nif05NetOdrCancelDa = new NIF05NetOdrCancelDa();

			// 注文状態確認 thêm
			nif05NetOdrCancelDa.NetConfirmOdrHdrStat(	odrNo,
														userCd,
														updateJobMod,
														out odrHstat,
														out errCode );
		}

		#endregion

		#region 締め対象チェック

		/// <summary>
		/// 締め対象チェック tiếng việt
		/// </summary>
		/// <param name="odrNo">注文番号</param>
		public byte CheckBatStat(long odrNo)
		{
			byte batStat = INT_ZERO;
			// 締め対象チェック
			OdrStatCheckDa odrStatCheckDa = new OdrStatCheckDa();
			batStat = odrStatCheckDa.CheckBatStat( odrNo );

			return batStat;
		}

		#endregion

		#region NET注文キャンセル登録

		/// <summary>
		/// NET注文キャンセル登録
		/// </summary>
		/// <param name="custNo">お客様番号</param>
		/// <param name="odrNo">注文番号</param>
		/// <param name="userCd">担当者コード</param>
		/// <param name="updateJobMod">更新バッチ名</param>
		/// <param name="success">処理成否判定</param>
		/// <param name="errCode">エラーコード</param>
		/// <param name="errMsg">エラーメッセージ</param>
		public void CancelOdrNet(	int custNo,
									long odrNo,
									string userCd,
									string updateJobMod,
									out int success,
									out int errCode,
									out string errMsg )
		{
			// NET注文キャンセル登録特殊データアクセス
			NIF05NetOdrCancelDa nif05NetOdrCancelDa = new NIF05NetOdrCancelDa();

			// NET注文キャンセル登録 ba
			nif05NetOdrCancelDa.CancelOdrNet(	custNo,
												odrNo,
												userCd,
												updateJobMod,
												out success,
												out errCode,
												out errMsg );
			if ( success != INT_ZERO )
			{
				// MessageCD：110057「*の登録に失敗しました。」
				throw new NonFatalException( this, MethodBase.GetCurrentMethod(), APMessage.SYS.CD110057, errMsg.ToString() );
			}
		}

		#endregion

		#region コンタクト履歴情報登録

		/// <summary>
		/// コンタクト履歴情報登録
		/// </summary>
		/// <param name="headerId">ヘダーID</param>
		/// <param name="custNo">お客様番号</param>
		/// <param name="odrAcptDt">受付日付</param>
		/// <param name="odrAcptTm">受付時刻</param>
		/// <param name="odrNo">注文番号</param>
		/// <param name="inContactHistNo">入力コンタクト履歴番号</param>
		/// <param name="userCd">担当者コード</param>
		/// <param name="UpdateWinMod">更新画面名</param>
		/// <param name="success">処理成否判定</param>
		/// <param name="errCode">エラーコード</param>
		/// <param name="errMsg">エラーメッセージ</param>
		public void HContactInput(	string headerId,
									int custNo,
									int odrAcptDt,
									int odrAcptTm,
									long odrNo,
									long inContactHistNo,
									string userCd,
									string UpdateWinMod,
									out int success,
									out int errCode,
									out string errMsg )
		{
			// NET注文キャンセル登録特殊データアクセス
			NIF05NetOdrCancelDa nif05NetOdrCancelDa = new NIF05NetOdrCancelDa();
			/*
			 NET注文キャンセル登録特殊データアクセス
			 コンタクト履歴情報登録tam
			*/
			nif05NetOdrCancelDa.HContactInput(	headerId,
												custNo,
												odrAcptDt,
												odrAcptTm,
												odrNo,
												inContactHistNo,
												userCd,
												UpdateWinMod,
												out success,
												out errCode,
												out errMsg );

			if ( success != INT_ZERO )
			{
				// MessageCD：110057「*の登録に失敗しました。」
				throw new NonFatalException( this, MethodBase.GetCurrentMethod(), APMessage.SYS.CD110057, errMsg.ToString() );
			}
		}

		#endregion
	}
}