using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Drawing;
using DocumentFormat.OpenXml.Drawing.Spreadsheet;
//using DocumentFormat.OpenXml.Office.Drawing;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Presentation;
using DocumentFormat.OpenXml.Spreadsheet;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ReadFile
{
	public class ExcelControl
	{
		#region GetSheetInfo

		/// <summary>
		/// GetSheetInfo
		/// </summary>
		/// <param name="fileName"></param>
		public static IEnumerable<Sheet> GetSheetInfo( string fileName )
		{
			// Open file as read-only.
			using ( SpreadsheetDocument mySpreadsheet = SpreadsheetDocument.Open( fileName, false ) )
			{
				Sheets sheets = mySpreadsheet.WorkbookPart.Workbook.Sheets;
				foreach ( Sheet sheet in sheets )
				{
					yield return sheet;
				}
			}
		}

		#endregion

		#region GetSelectedSharedString

		/// <summary>
		/// GetSelectedSharedString
		/// </summary>
		/// <param name="inpFileNamePath"></param>
		/// <param name="selectedSheets"></param>
		/// <returns></returns>
		public static SortedList<int, CheckData> GetSelectedSharedString( string inpFileNamePath, List<Sheet> selectedSheets, string inpFileName )
		{
			SortedList<int, CheckData> selectedSharedList = new SortedList<int, CheckData>();

			using ( SpreadsheetDocument spreadsheetDocument = SpreadsheetDocument.Open( inpFileNamePath, false ) )
			{
				if ( spreadsheetDocument.WorkbookPart.GetPartsOfType<SharedStringTablePart>().Count() > 0 )
				{
					SharedStringTablePart shareStringPart = spreadsheetDocument.WorkbookPart.GetPartsOfType<SharedStringTablePart>().First();
					IEnumerable<SharedStringItem> sharedItems = shareStringPart.SharedStringTable.Elements<SharedStringItem>();

					WorkbookPart wbPart = spreadsheetDocument.WorkbookPart;
					WorksheetPart wsPart;
					int sharedItemIndex = 0;
					Sheets sheetsInFileCheck = spreadsheetDocument.WorkbookPart.Workbook.Sheets;

					foreach ( Sheet sheet in sheetsInFileCheck )
					{
						// kiem tra ton tai sheet duoc chon va trong file duoc kiem tra
						if ( HasSheetNameSelected( selectedSheets, sheet.Name ) == true )
						{
							// Retrieve a reference to the worksheet part.
							wsPart = ( WorksheetPart )( wbPart.GetPartById( sheet.Id ) );

							foreach ( Cell cell in wsPart.Worksheet.Descendants<Cell>().Where( c => c.DataType != null ) )
							{
								if ( cell.DataType == CellValues.SharedString )
								{
									sharedItemIndex = Int32.Parse( cell.InnerText );
									if ( !selectedSharedList.ContainsKey( sharedItemIndex ) )
									{
										CheckData chkData = new CheckData();
										chkData.FileName = inpFileName;
										chkData.SheetName = sheet.Name;
										chkData.Taget = cell.CellReference;
										chkData.Content = sharedItems.ElementAt( sharedItemIndex ).InnerText;
										selectedSharedList.Add( sharedItemIndex, chkData );
									}
								}
							}
						}
					}
				}
			}

			return selectedSharedList;
		}

		#endregion

		#region GetDrawingsPart

		/// <summary>
		/// GetDrawingsPart
		/// </summary>
		/// <param name="inpFileNamePath"></param>
		/// <returns></returns>
		public static SortedList<int, CheckData> GetDrawingsPart( string inpFileNamePath, string inpFileName, List<Sheet> selectedSheets )
		{
			SortedList<int, CheckData> sortedList = new SortedList<int, CheckData>();
			using ( SpreadsheetDocument spreadsheetDocument = SpreadsheetDocument.Open( inpFileNamePath, isEditable: false ) )
			{
				int num = 0;
				WorkbookPart workbookPart = spreadsheetDocument.WorkbookPart;
				foreach ( WorksheetPart item in from a in workbookPart.WorksheetParts
												orderby a.Uri.OriginalString
												select a )
				{
					if ( item.DrawingsPart != null )
					{
						WorksheetDrawing worksheetDrawing = item.DrawingsPart.WorksheetDrawing;
						Sheet sheet = GetSheetFromWorkSheet( workbookPart, item );
						string sheetName = sheet.Name;

						if ( HasSheetNameSelected( selectedSheets, sheetName ) == true )
						{
							foreach ( TwoCellAnchor twoCell in worksheetDrawing.Descendants<TwoCellAnchor>() )
							{
								string content = string.Empty;
								content = GetTwoCellAnchorText( twoCell );
								CheckData chkData = new CheckData();
								chkData.FileName = inpFileName;
								chkData.SheetName = sheet.Name;
								chkData.Taget = "object coordinates (Col: " + twoCell.FromMarker.ColumnId.Text + ", Row: " + twoCell.FromMarker.RowId.Text + ")";
								chkData.Content = content;
								sortedList.Add( num, chkData );
								num++;
							}

							foreach ( OneCellAnchor oneCell in worksheetDrawing.Descendants<OneCellAnchor>() )
							{
								string content = string.Empty;
								content = GetOneCellAnchorText( oneCell );
								CheckData chkData = new CheckData();
								chkData.FileName = inpFileName;
								chkData.SheetName = sheet.Name;
								chkData.Taget = "object coordinates (Col: " + oneCell.FromMarker.ColumnId.Text + ", Row: " + oneCell.FromMarker.RowId.Text + ")";
								chkData.Content = content;
								sortedList.Add( num, chkData );
								num++;
							}
						}
					}
				}
			}

			return sortedList;
		}

		#endregion

		#region HasSheetNameSelected

		/// <summary>
		/// HasSheetNameSelected
		/// </summary>
		/// <param name="selectedSheets"></param>
		/// <param name="sheetName"></param>
		/// <returns></returns>
		private static bool HasSheetNameSelected( List<Sheet> selectedSheets, string sheetName )
		{
			for ( int i = 0; i < selectedSheets.Count; i++ )
			{
				if ( selectedSheets[i].Name == sheetName )
				{
					return true;
				}
			}

			return false;
		}

		#endregion

		#region GetSheetFromWorkSheet

		/// <summary>
		/// GetSheetFromWorkSheet
		/// </summary>
		/// <param name="workbookPart"></param>
		/// <param name="worksheetPart"></param>
		/// <returns></returns>
		private static Sheet GetSheetFromWorkSheet( WorkbookPart workbookPart, WorksheetPart worksheetPart )
		{
			string relationshipId = workbookPart.GetIdOfPart( worksheetPart );
			IEnumerable<Sheet> sheets = workbookPart.Workbook.Sheets.Elements<Sheet>();
			return sheets.FirstOrDefault( s => s.Id.HasValue && s.Id.Value == relationshipId );
		}

		#endregion

		# region tree diagram
		/// <summary>
		/// 
		/// </summary>
		/// <param name="shapeTree"></param>
		/// <returns></returns>
		private static string GetTreeText( AbsoluteAnchor shapeTree )
		{
			StringBuilder builder = new StringBuilder();
			List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape> lstShape = new List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape>();

			for ( int i = 0; i < shapeTree.ChildElements.Count; i++ )
			{
				if ( shapeTree.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape )
				{
					GetAllShapes( ref lstShape, shapeTree.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape );
				}
				else if ( shapeTree.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape )
				{
					lstShape.Add( shapeTree.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape );
				}
			}

			foreach ( DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape shape in lstShape )
			{
				if ( shape != null )
				{
					DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody textBody = shape.GetFirstChild<DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody>();
					if ( textBody != null )
					{
						builder.Clear();
						foreach ( Paragraph item in from c in textBody.ChildElements
													where c is Paragraph
													select c )
						{
							for ( int i = 0; i < item.ChildElements.Count; i++ )
							{
								if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Run )
								{
									builder.Append( ( item.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Run ).Text.Text );
								}
								else if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Break )
								{
									builder.Append( Environment.NewLine );
								}
							}
							builder.Append( Environment.NewLine );
						}

						return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
					}
				}
			}

			return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
		}
		#endregion

		#region GetOneCellAnchorText

		/// <summary>
		/// GetOneCellAnchorText
		/// </summary>
		/// <param name="cellAnchor"></param>
		/// <returns></returns>
		private static string GetOneCellAnchorText( OneCellAnchor cellAnchor )
		{
			StringBuilder builder = new StringBuilder();
			List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape> lstShape = new List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape>();

			for ( int i = 0; i < cellAnchor.ChildElements.Count; i++ )
			{
				if ( cellAnchor.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape )
				{
					GetAllShapes( ref lstShape, cellAnchor.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape );
				}
				else if ( cellAnchor.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape )
				{
					lstShape.Add( cellAnchor.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape );
				}
			}

			foreach ( DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape shape in lstShape )
			{
				if ( shape != null )
				{
					DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody textBody = shape.GetFirstChild<DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody>();
					if ( textBody != null )
					{
						builder.Clear();
						foreach ( Paragraph item in from c in textBody.ChildElements
													where c is Paragraph
													select c )
						{
							for ( int i = 0; i < item.ChildElements.Count; i++ )
							{
								if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Run )
								{
									builder.Append( ( item.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Run ).Text.Text );
								}
								else if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Break )
								{
									builder.Append( Environment.NewLine );
								}
							}
							builder.Append( Environment.NewLine );
						}

						return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
					}
				}
			}

			return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
		}

		#endregion

		#region GetTwoCellAnchorText

		/// <summary>
		/// GetTwoCellAnchorText
		/// </summary>
		/// <param name="cellAnchor"></param>
		/// <returns></returns>
		private static string GetTwoCellAnchorText( TwoCellAnchor cellAnchor )
		{
			StringBuilder builder = new StringBuilder();
			List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape> lstShape = new List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape>();

			for ( int i = 0; i < cellAnchor.ChildElements.Count; i++ )
			{
				if ( cellAnchor.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape )
				{
					GetAllShapes( ref lstShape, cellAnchor.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape );
				}
				else if ( cellAnchor.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape )
				{
					lstShape.Add( cellAnchor.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape );
				}
			}

			foreach ( DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape shape in lstShape )
			{
				if ( shape != null )
				{
					DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody textBody = shape.GetFirstChild<DocumentFormat.OpenXml.Drawing.Spreadsheet.TextBody>();
					if ( textBody != null )
					{
						builder.Clear();
						foreach ( Paragraph item in from c in textBody.ChildElements
													where c is Paragraph
													select c )
						{
							for ( int i = 0; i < item.ChildElements.Count; i++ )
							{
								if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Run )
								{
									builder.Append( ( item.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Run ).Text.Text );
								}
								else if ( item.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Break )
								{
									builder.Append( Environment.NewLine );
								}
							}
							builder.Append( Environment.NewLine );
						}

						return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
					}
				}
			}

			return builder.ToString().TrimEnd( Environment.NewLine.ToCharArray() );
		}

		#endregion

		#region GetAllShapes

		/// <summary>
		/// GetAllShapes
		/// </summary>
		/// <param name="lstShape"></param>
		/// <param name="control"></param>
		private static void GetAllShapes( ref List<DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape> lstShape, DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape control )
		{
			for ( int i = 0; i < control.ChildElements.Count; i++ )
			{
				if ( control.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape )
				{
					GetAllShapes( ref lstShape, control.ChildElements[i] as DocumentFormat.OpenXml.Drawing.Spreadsheet.GroupShape );
				}
				else if ( control.ChildElements[i] is DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape )
				{
					lstShape.Add( ( DocumentFormat.OpenXml.Drawing.Spreadsheet.Shape )control.ChildElements[i] );
				}
			}
		}

		#endregion
	}
}
